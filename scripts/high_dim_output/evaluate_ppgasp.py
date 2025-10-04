import argparse
import os
import json
import numpy as np
import h5py
import time
from psimpy.emulator import PPGaSP
from high_dim_gp.utils import ErrorMetrics

def descale_data(test_y: np.ndarray,
                 mean_scaled: np.ndarray,
                 std_scaled: np.ndarray,
                 lower95_scaled: np.ndarray,
                 upper95_scaled: np.ndarray,
                 scaler_mean: np.ndarray,
                 scaler_scale: np.ndarray):
    groud_truth = test_y * scaler_scale + scaler_mean
    mean = mean_scaled * scaler_scale + scaler_mean
    std = std_scaled * scaler_scale
    lower95 = lower95_scaled * scaler_scale + scaler_mean
    upper95 = upper95_scaled * scaler_scale + scaler_mean
    return groud_truth, mean, std, lower95, upper95

def main():
    # 1. Parse arguments
    p = argparse.ArgumentParser()
    p.add_argument("--input-dir",  required=True)
    p.add_argument("--output-dir", required=True)
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
    emulator = PPGaSP(ndim=X_train.shape[1])
    start_time = time.time()
    emulator.train(design=X_train, response=Y_train)
    training_time = time.time() - start_time
    
    # 4. Predict
    start_time = time.time()
    predictions = emulator.predict(X_test)
    infer_time = time.time() - start_time
    
    
    # 5. Descale and filter out predictive values below threshold
    predictions_mean = predictions[:, :, 0]
    predictions_lower = predictions[:, :, 1]
    predictions_upper = predictions[:, :, 2]
    predictions_std = predictions[:, :, 3]
    
    ground_truths, predictions_mean, predictions_std, predictions_lower, predictions_upper = descale_data(
        Y_test, predictions_mean, predictions_std, predictions_lower, predictions_upper, scaler_mean, scaler_scale
    )
    ground_truths = np.where(ground_truths < args.threshold, 0, ground_truths)
    predictions_mean = np.where(predictions_mean < args.threshold, 0, predictions_mean)
    predictions_lower = np.where(predictions_mean < args.threshold, 0, predictions_lower)
    predictions_upper = np.where(predictions_mean < args.threshold, 0, predictions_upper)
    predictions_std = np.where(predictions_mean < args.threshold, 0, predictions_std)
        
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
        name="PPGaSP",
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
    print(f"[PPGaSP] metrics → {args.output_dir}/metrics.json")

if __name__=="__main__":
    main()