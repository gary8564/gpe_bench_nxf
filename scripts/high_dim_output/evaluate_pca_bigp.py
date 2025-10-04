import argparse
import os
import json
import numpy as np
import h5py
from high_dim_gp.emulator import PCA_BiGP
from high_dim_gp.dr import OutputDimReducer, LinearPCA
from high_dim_gp.utils import ErrorMetrics

def main():
    # 1. Parse arguments
    p = argparse.ArgumentParser()
    p.add_argument("--input-dir",  required=True)
    p.add_argument("--output-dir", required=True)
    p.add_argument("--device", default="cpu")
    p.add_argument("--threshold", type=float, required=True)
    p.add_argument("--num-epochs", type=int, default=100)
    p.add_argument("--lr", type=float, default=0.05)
    p.add_argument("--optim", default="adamw")
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
    
    # 3. Train
    output_reducer = OutputDimReducer(LinearPCA(n_components=10))
    emulator = PCA_BiGP(output_reducer, device=args.device, kernel_type='matern_5_2')
    training_time = emulator.train(X_train,
                                   Y_train,
                                   num_epochs=args.num_epochs,
                                   lr=args.lr,
                                   optim=args.optim)
    
    # 4. Predict
    mean, std, _, _, infer_time = emulator.predict(X_test)
    
    # 5. Postprocessing: reconstruct back to original space
    mean_original, std_original, lower_CI, upper_CI = emulator.postprocess_invert_back(mean, std, scaler_mean, scaler_scale)
    
    # 5. Descale and filter out predictive values below threshold
    ground_truths = Y_test * scaler_scale + scaler_mean
    ground_truths = np.where(ground_truths < args.threshold, 0, ground_truths)
    predictions_mean = np.where(mean_original < args.threshold, 0, mean_original)
    predictions_lower = np.where(mean_original < args.threshold, 0, lower_CI)
    predictions_upper = np.where(mean_original < args.threshold, 0, upper_CI)
    predictions_std = np.where(mean_original < args.threshold, 0, std_original)
        
    # 6. Evaluate metrics
    rmse = ErrorMetrics.RMSE(predictions=predictions_mean, observations=ground_truths)
    coverage_prob = ErrorMetrics.CoverageProbability(predictions_mean, 
                                                    predictions_lower, 
                                                    predictions_upper,
                                                    ground_truths)
    quantile_coverage_error = ErrorMetrics.QuantileCoverageError(predictions_lower, 
                                                                predictions_upper,
                                                                ground_truths)
    
    # 7. Save metrics
    os.makedirs(args.output_dir, exist_ok=True)
    metrics = dict(
        name="PCA-BiGP",
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
    print(f"[PCA-BiGP] metrics → {args.output_dir}/metrics.json")

if __name__=="__main__":
    main()