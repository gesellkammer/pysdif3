# sdifinfo


This command-line script is distributed with pysdif3. It allows to query information about a .sdif file
as well as dump its data.


## Usage

```
usage: sdifinfo [-h] [-d] sdiffile

positional arguments:
  sdiffile

options:
  -h, --help  show this help message and exit
  -d, --dump  Dump data
````

## Example

```bash

$ sdifinfo --dump

» sdifinfo -d AO.sdif
1NVT
{
EndTime 5.00;
SamplingRate    44100.;
ChantMaxNbSubObjs       5;
}

1TYP
{
  1MTD  1FOF    {Frequency, Amplitude, BandWidth, Tex, DebAtt, Atten, Phase}
  1MTD  1CHA    {Channel1, Channel2}
  1MTD  1FQ0    {Frequency, Confidence, Score, RealAmplitude}
  1FTD  1FOB
        {
          1FQ0  FundamentalFrequencyEstimate;
          1FOF  Formants;
          1CHA  Channels;
        }
}

1IDS
{
  0 Chant:Patch0/1/FOB/1/5/0./5.;
}


Frame #0, sig: 1FOB, 0.000000 s
  Matrix 1FQ0, shape: 1 rows x 1 cols
        [[110.]]
  Matrix 1FOF, shape: 5 rows x 7 cols
        [[ 650.        1.       80.        0.002     0.05      0.004     0.    ]
         [1080.        0.5012   90.        0.002     0.05      0.004     0.    ]
         [2650.        0.4467  120.        0.002     0.05      0.004     0.    ]
         [2900.        0.3982  130.        0.002     0.05      0.004     0.    ]
         [3250.        0.0795  140.        0.002     0.05      0.004     0.    ]]
  Matrix 1CHA, shape: 5 rows x 1 cols
        [[1.]
         [1.]
         [1.]
         [1.]
         [1.]]

Frame #1, sig: 1FOB, 1.000000 s
  Matrix 1FQ0, shape: 1 rows x 1 cols
        [[110.]]
  Matrix 1FOF, shape: 5 rows x 7 cols
        [[ 650.        1.       80.        0.002     0.05      0.004     0.    ]
         [1080.        0.5012   90.        0.002     0.05      0.004     0.    ]
         [2650.        0.4467  120.        0.002     0.05      0.004     0.    ]
         [2900.        0.3982  130.        0.002     0.05      0.004     0.    ]
         [3250.        0.0795  140.        0.002     0.05      0.004     0.    ]]

Frame #2, sig: 1FOB, 4.000000 s
  Matrix 1FQ0, shape: 1 rows x 1 cols
        [[110.]]
  Matrix 1FOF, shape: 5 rows x 7 cols
        [[ 400.        1.       40.        0.002     0.05      0.004     0.    ]
         [ 800.        0.3163   80.        0.002     0.05      0.004     0.    ]
         [2600.        0.2512  100.        0.002     0.05      0.004     0.    ]
         [2800.        0.2512  120.        0.002     0.05      0.004     0.    ]
         [3000.        0.0501  120.        0.002     0.05      0.004     0.    ]]

Global statistics:
    0.000000s - 4.000000s     # frames: 3    # matrices: 7

    1FOB: 3 frames
```




