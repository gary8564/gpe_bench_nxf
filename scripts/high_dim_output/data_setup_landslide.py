import numpy as np
import rasterio
import argparse
import os

def load_dataset(input_filepath, output_filepath):
    input_data = np.genfromtxt(input_filepath, delimiter=',', skip_header=1)
    with rasterio.open(output_filepath) as output:
        rows = output.height
        cols = output.width
        size = output.count
        output_data = np.zeros((size, rows, cols))
        for sim in range(size):
            output_data[sim, :] = output.read(sim + 1).reshape(1, rows, cols)  
    return input_data, output_data

def main():
    # 1. Parse arguments
    p = argparse.ArgumentParser()
    p.add_argument("--input-dir", required=True,
                   help="Directory containing extracted synthetic data")
    p.add_argument("--output-dir", required=True,
                   help="Store processed train_X.npy, train_Y.npy, test_X.npy, test_Y.npy")
    p.add_argument("--qoi", required=True,
                   help="Quantity of interest",
                   choices=["hmax", "vmax"])
    args = p.parse_args()
    
    # 2. Check if input directory exists
    if not os.path.exists(args.input_dir):
        raise ValueError(f"Input directory does not exist: {args.input_dir}")
    train_data_root_folder = os.path.join(args.input_dir, "train")
    test_data_root_folder = os.path.join(args.input_dir, "test")
    train_input_filepath = os.path.join(train_data_root_folder, "input", "synth_emulator.csv")
    train_output_filepath = os.path.join(train_data_root_folder, "output", args.qoi + "_stack.tif") 
    test_input_filepath = os.path.join(test_data_root_folder, "input", "synth_validation_emulator.csv")
    test_output_filepath = os.path.join(test_data_root_folder, "output", args.qoi + "_stack.tif") 
    
    # 3. Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # 4. Load synthetic data
    train_X, train_Y = load_dataset(train_input_filepath, train_output_filepath)
    test_X, test_Y = load_dataset(test_input_filepath, test_output_filepath)
    
    # 5. Save data
    np.save(os.path.join(args.output_dir, "train_X.npy"), train_X)
    np.save(os.path.join(args.output_dir, "train_Y.npy"), train_Y)
    np.save(os.path.join(args.output_dir, "test_X.npy"), test_X)
    np.save(os.path.join(args.output_dir, "test_Y.npy"), test_Y)
    print(f"""[data_setup_synthetic] saved 
          input → {args.output_dir}/train_X.npy (shape: {train_X.shape})
                  {args.output_dir}/test_X.npy (shape: {test_X.shape})
          output → {args.output_dir}/train_Y.npy (shape: {train_Y.shape})
                   {args.output_dir}/test_Y.npy (shape: {test_Y.shape})""")
if __name__ == "__main__":
    main()