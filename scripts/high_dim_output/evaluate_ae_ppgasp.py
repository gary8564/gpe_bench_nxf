import argparse
import os
import json
import torch
import torch.nn as nn
import numpy as np
import h5py
import time
from psimpy.emulator import PPGaSP
from high_dim_gp.dr import AutoEncoder
from high_dim_gp.utils import ErrorMetrics, uncertainty_propagation

def train_ae(model: AutoEncoder, Y_train: torch.Tensor, device: str = "cpu"):
    Y_train = Y_train.to(device)
    loss_function = nn.MSELoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=0.001)
    # Training
    losses = []
    num_epochs = 500
    model.train()
    start_time = time.time()
    for epoch in range(num_epochs):
        outputs = model(Y_train)
        loss = loss_function(outputs, Y_train)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
        losses.append(loss.item())
        print(f'Epoch [{epoch + 1}/{num_epochs}], Loss: {loss.item():.4f}')
    # Encoding the data using the trained variational autoencoder
    model.eval()
    with torch.no_grad():
        Y_train_reduced = model.encoder(Y_train).detach().numpy()
    dr_processing_time = time.time() - start_time
    return Y_train_reduced, dr_processing_time

def main():
    # 1. Parse arguments
    p = argparse.ArgumentParser()
    p.add_argument("--input-dir",  required=True)
    p.add_argument("--output-dir", required=True)
    p.add_argument("--threshold", type=float, required=True)
    p.add_argument("--latent-dim", type=int, required=True)
    p.add_argument("--device", default="cpu")
    args = p.parse_args()
    
    # 2. Load data from HDF5
    hdf5_file = os.path.join(args.input_dir, "data.h5")
    with h5py.File(hdf5_file, 'r') as f:
        X_train = f['train_X'][:]
        Y_train = f['train_Y'][:]
        X_test = f['test_X'][:]
        Y_test = f['test_Y'][:]
        
        # Load standardization parameters
        scaler_mean = f['output_scaler_mean'][:]
        scaler_scale = f['output_scaler_scale'][:]
        
    # 3. Train AE
    Y_train_tensor = torch.FloatTensor(Y_train)
    input_dim = Y_train_tensor.shape[1]
    latent_dim = args.latent_dim
    model = AutoEncoder(input_dim=input_dim, latent_dim=latent_dim, hidden_dims=[1024, 256, 64, 64, 16])
    Y_train_reduced, dr_processing_time = train_ae(model, Y_train_tensor, device=args.device)
    
    # 4. Train
    emulator = PPGaSP(ndim=X_train.shape[1])
    start_time = time.time()
    emulator.train(design=X_train, response=Y_train_reduced)
    gp_training_time = time.time() - start_time
    training_time = dr_processing_time + gp_training_time
    
    # 5. Predict
    start_time = time.time()
    predictions = emulator.predict(X_test)
    gp_infer_time = time.time() - start_time
    
    # 6. Reconstruct back to orginal space, descale and filter out predictive values below threshold
    start_time = time.time()
    predictions_mean, predictions_lower, predictions_upper, predictions_std = uncertainty_propagation(model, Y_train, predictions, scaler_mean, scaler_scale, device=args.device)
    postprocessing_time = time.time() - start_time
    infer_time = gp_infer_time + postprocessing_time
    ground_truths = Y_test * scaler_scale + scaler_mean
    ground_truths = np.where(ground_truths < args.threshold, 0, ground_truths)
    predictions_mean = np.where(predictions_mean < args.threshold, 0, predictions_mean)
    predictions_lower = np.where(predictions_mean < args.threshold, 0, predictions_lower)
    predictions_upper = np.where(predictions_mean < args.threshold, 0, predictions_upper)
    predictions_std = np.where(predictions_mean < args.threshold, 0, predictions_std)
        
    # 7. Evaluate metrics
    rmse = ErrorMetrics.RMSE(predictions=predictions_mean, observations=ground_truths)
    coverage_prob = ErrorMetrics.CoverageProbability(predictions_mean, 
                                                    predictions_lower, 
                                                    predictions_upper,
                                                    ground_truths)
    quantile_coverage_error = ErrorMetrics.QuantileCoverageError(predictions_lower, 
                                                                predictions_upper,
                                                                ground_truths)
    
    # 8. Save metrics
    os.makedirs(args.output_dir, exist_ok=True)
    metrics = dict(
        name="AE-PPGaSP",
        ground_truth=ground_truths.tolist(),
        predictions_mean=predictions_mean.tolist(),
        predictions_std=predictions_std.tolist(),
        predictions_lower95=predictions_lower.tolist(),
        predictions_upper95=predictions_upper.tolist(),
        rmse=float(rmse),
        coverage_prob=float(coverage_prob),
        quantile_coverage_error=float(quantile_coverage_error),
        train_time=float(training_time),
        infer_time=float(infer_time)
    )
    with open(os.path.join(args.output_dir,"metrics.json"),"w") as f:
        json.dump(metrics, f, indent=2)
    print(f"[AE-PPGaSP] metrics → {args.output_dir}/metrics.json")

if __name__=="__main__":
    main()