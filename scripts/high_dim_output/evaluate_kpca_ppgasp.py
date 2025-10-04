import argparse
import os
import json
import numpy as np
import h5py
from high_dim_gp.emulator import PCAPPGaSP
from high_dim_gp.dr import OutputDimReducer, NonlinearPCA
from high_dim_gp.utils import ErrorMetrics

def main():
    # 1. Parse arguments
    p = argparse.ArgumentParser()
    p.add_argument("--input-dir",  required=True)
    p.add_argument("--output-dir", required=True)
    p.add_argument("--n-components", type=int, required=True)
    p.add_argument("--threshold", type=float, required=True)
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
    pca = NonlinearPCA(n_components=args.n_components, alpha=1e-10)
    output_reducer  = OutputDimReducer(pca)
    model = PCAPPGaSP(
        ndim=X_train.shape[1],
        output_dim_reducer=output_reducer,
    )
    training_time = model.train(X_train, Y_train)
    
    # 4. Predict
    predictions_latent, predictions_mean_original, infer_time, predictions_uncertainty = model.predict(X_test, scaler_mean, scaler_scale, uncertainty_reconstruction=True)
    
    
    # 5. Descale and filter out predictive values below threshold
    ground_truths = Y_test * scaler_scale + scaler_mean
    ground_truths = np.where(ground_truths < args.threshold, 0, ground_truths)
    predictions_mean = np.where(predictions_mean_original < args.threshold, 0, predictions_mean_original)
    predictions_lower = np.where(predictions_mean_original < args.threshold, 0, predictions_uncertainty[:, :, 0])
    predictions_upper = np.where(predictions_mean_original < args.threshold, 0, predictions_uncertainty[:, :, 1])
    predictions_std = np.where(predictions_mean_original < args.threshold, 0, predictions_uncertainty[:, :, 2])
        
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
        name="kPCA-PPGaSP",
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
    print(f"[kPCA-PPGaSP] metrics → {args.output_dir}/metrics.json")

if __name__=="__main__":
    main()