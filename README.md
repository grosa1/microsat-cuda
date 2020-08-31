<!--
*** Thanks for checking out this README Template. If you have a suggestion that would
*** make this better, please fork the repo and create a pull request or simply open
*** an issue with the tag "enhancement".
*** Thanks again! Now go create something AMAZING! :D
***
***
***
*** To avoid retyping too much info. Do a search and replace for the following:
*** github_username, repo_name, twitter_handle, email
-->





<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]
-->



<!-- PROJECT LOGO 
<br />
<p align="center">
  <a href="https://github.com/github_username/repo_name">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>
-->
  <h3 align="center">MicroSAT-CUDA</h3>

  <p align="center">
CUDA porting of MicroSAT https://github.com/marijnheule/microsat

MicroSAT is a simple CDCL SAT solver, originally created by [MarijnHeule and Armin Biere](https://github.com/marijnheule/microsat). It aims at being very short (300 lines of code in-cluding comments) and has neither position saving nor blocking literals. Based on the CDCL procedure, performs unit propagation using two-watched literals and is extremely fast in solving small formulas.

We made a port for CUDA GPUs, to test its performance in parallel resolution of a large amount of formulas.

The `dimacs` folder contains SAT and UNSAT formulas in [DIMACS](https://logic.pdmi.ras.ru/~basolver/dimacs.html) format ready to be used with MicroSAT-CUDA. The formulas are generated using a CNF formula generator ([CNFgen](https://github.com/MassimoLauria/cnfgen)).
A different DIMACS generator can be found at https://toughsat.appspot.com/.

For further details, please refer to [report]().

<!--
    <br />
    <a href="https://github.com/github_username/repo_name"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/github_username/repo_name">View Demo</a>
    ·
    <a href="https://github.com/github_username/repo_name/issues">Report Bug</a>
    ·
    <a href="https://github.com/github_username/repo_name/issues">Request Feature</a>
  </p>
</p>
-->


<!-- TABLE OF CONTENTS -->
## Table of Contents

* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
* [Usage](#usage)
  * [Supported params](#supported-params)
  * [Build and run](#build-and-run)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)

<!--
* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)
-->



<!-- ABOUT THE PROJECT -->
<!--
## About The Project

[![Product Name Screen Shot][product-screenshot]](https://example.com)

Here's a blank template to get started:
**To avoid retyping too much info. Do a search and replace with your text editor for the following:**
`github_username`, `repo_name`, `twitter_handle`, `email`


### Built With

* []()
* []()
* []()

-->


<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

* C compilers
* CUDA drivers, to run `nvcc` command required for build
* On Windows, you need to install `dirent.h` which is used to list input files
* An IDE that supports CUDA, for example:
  * [Visual Studio with CUDA plugin](https://visualstudio.microsoft.com/it/)
  * [Eclipse Nsight](https://developer.nvidia.com/nsight-visual-studio-edition)

<!--
### Installation

 * Clone the repo
```sh
git clone https://github.com/grosa1/microsat-cuda.git
```
 * Build MicroSAT-CUDA
For Linux-based systems, run the following command:
``` 
nvcc -o mcuda .\microsat_cuda.cu 
```

 * For Windows, put `dirent.h` in a new folder called `include` and run:
``` 
nvcc -I .\include\ -o mcuda .\microsat_cuda.cu 
```

The process is the same for **MicroSAT-CUDAv2** (`microsat_cuda_malloc_opt.cu`) and **MicroSAT-CUDAv3** (`microsat_cuda_multi_gpu.cu`).
-->


<!-- USAGE EXAMPLES -->
## Usage

### Supported params:
  * `formulas dir`, set the folder containing the dimacs files;
  * `DB_MAX_MEM`, set the memory db used by the solver to store clauses and variable assignments;
  * `CLAUSE_LEARN_MAX_MEM`, set the maxium memory that can ve used for clause learning;
  * `INITIAL_MAX_LEMMAS`, set the initial threshold for lemmas. It directly affects the growth of the clause database;
  * `GPU_COUNT` (only for v3), set the number of GPUs to be used by the solver.

### Build and run
There are mainly 3 versions of MicroSAT-CUDA:

* **MicroSAT-CUDAv1** (`microsat_cuda.cu`), which is the first version that uses a different mem area for each formula:
``` 
# Build
nvcc -o mcudav1 .\microsat_cuda.cu 

# Run
./mcudav1 <formulas dir> <DB_MAX_MEM> <CLAUSE_LEARN_MAX_MEM> <INITIAL_MAX_LEMMAS>
```

* **MicroSAT-CUDAv2** (`microsat_cuda_malloc_opt.cu`), which is the second version with some memory optimizations:
``` 
# Build
nvcc -o mcudav2 .\microsat_cuda_malloc_opt.cu 

# Run
./mcudav2 <formulas dir> <DB_MAX_MEM> <CLAUSE_LEARN_MAX_MEM> <INITIAL_MAX_LEMMAS>
```

* **MicroSAT-CUDAv3** (`microsat_cuda_multi_gpu.cu`), which is the v2 adapted for multi-GPU support. If you only need a single-GPU run, please refer to MicroSAT-CUDAv2.
``` 
# Build
nvcc -o mcudav3 .\microsat_cuda_multi_gpu.cu 

# Run
./mcudav3 <formulas dir> <DB_MAX_MEM> <CLAUSE_LEARN_MAX_MEM> <INITIAL_MAX_LEMMAS> <GPU_COUNT>
```

### Utils
* In `slurm` folder, there are the SLURM config files used for the test executed on [Iridis 5](https://www.southampton.ac.uk/isolutions/staff/iridis.page) cluster.
* In `script` folder, there are the script used for the execution of the tests that also can be executed on a normal PC.


<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/github_username/repo_name/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

* [Giovanni](https://github.com/grosa1)
* [Massimo](https://github.com/MassimoPiedimonte)

Project Link: [https://github.com/grosa1/microsat-cuda](https://github.com/grosa1/microsat-cuda)



<!-- ACKNOWLEDGEMENTS -->
<!--
## Acknowledgements

* []()
* []()
* []()
-->




<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/github_username/repo.svg?style=flat-square
[contributors-url]: https://github.com/github_username/repo/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/github_username/repo.svg?style=flat-square
[forks-url]: https://github.com/github_username/repo/network/members
[stars-shield]: https://img.shields.io/github/stars/github_username/repo.svg?style=flat-square
[stars-url]: https://github.com/github_username/repo/stargazers
[issues-shield]: https://img.shields.io/github/issues/github_username/repo.svg?style=flat-square
[issues-url]: https://github.com/github_username/repo/issues
[license-shield]: https://img.shields.io/github/license/github_username/repo.svg?style=flat-square
[license-url]: https://github.com/github_username/repo/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/github_username
[product-screenshot]: images/screenshot.png
