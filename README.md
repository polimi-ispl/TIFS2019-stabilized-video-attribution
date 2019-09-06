# Facing Device Attribution Problem for Stabilized Video Sequences
### Publications
- S. Mandelli, P. Bestagini, L. Verdoliva, and S. Tubaro,
*Facing Device Attribution Problem for Stabilized Video Sequences*. IEEE Transaction on Information Forensics and Security, 2019, Early Access Article.
[Available at IEEE Xplore](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8721076)
### Dataset
Videos come from Vision dataset [1]:
- "nonstabilized_videos_dataset.csv" includes the complete list of investigated non stabilized videos
- "stabilized_videos_dataset.csv" includes the complete list of investigated stabilized videos
### Code
In order to run the code, follow these steps:
- Download the Camera-fingerprint package from "http://dde.binghamton.edu/download/camera_fingerprint"
- Run the function "compile.m" in folder "CameraFingerprint/Filter".

To compute the reference video fingerprint from videos only:
- Run "compute_Kv.m"

To test the video query:
- Run "test_query_video.m"

### References
- D. Shullani, M. Fontani, M. Iuliani, O. Al Shaya, and A. Piva,
*VISION: a video and image dataset for source identification*. EURASIP Journal on Information Security, 2017(1), p.15.
[Available at EURASIP Journal on Information Security](https://doi.org/10.1186/s13635-017-0067-2)
