import argparse
import numpy as np

import cv2

parser = argparse.ArgumentParser(description="Processes an input for header")
parser.add_argument("input", type=str, help="Name of input image.")
parser.add_argument("--output", type=str, help="Filename of output image.")


def main():
    args = parser.parse_args()
    image = cv2.imread(args.input)
    image = cv2.GaussianBlur(image, (7,7), 0)
    image = np.ndarray.astype(image, np.int32)
    image[:, :, :] = np.maximum(0, image[:, :, :] - 0.5 * image[:, :, :] - 15)  # This is HSV, not RGB!
    image = np.ndarray.astype(image, np.uint8)
    cv2.imwrite(args.output, image)


if __name__ == "__main__":
    main()
