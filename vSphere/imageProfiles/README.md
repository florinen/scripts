# Create custom image Profiles:
 1. First you will need to download Offline bundle from VMware ESXi Online depot. Change Dir to where the script resides.
 The script will download specific Base ImageProfile, in this case above v7.0 by specifying "-v70" flag, change this flag for other versions to be displayed. 
 Using OLD script: 
 ```
 .\ESXi-Customizer-PS-v2.6.0.ps1 -v70 -sip -ozip -outDir 'C:\path\to\where\you\save\bundle.zip' -log 'C:\path\to\where\you\save\logs\ESXi-Customizer.log' -nsc
 ```
 Using the NEW script:
 ```
 .\ESXi-Customizer-PS-v2.8.1.ps1 -v70 -sip -ozip -outDir 'C:\path\to\where\you\save\bundle.zip' -log 'C:\path\to\where\you\save\logs\ESXi-Customizer.log' -nsc
 ```
 Ex:
 ```
 Select Base Imageprofile:
-------------------------------------------
1 : ESXi-7.0U1sc-17325020-standard
2 : ESXi-7.0U1sc-17325020-no-tools
3 : ESXi-7.0U1c-17325551-standard
4 : ESXi-7.0U1c-17325551-no-tools
5 : ESXi-7.0U1b-17168206-standard
6 : ESXi-7.0U1b-17168206-no-tools
7 : ESXi-7.0U1a-17119627-standard
8 : ESXi-7.0U1a-17119627-no-tools
9 : ESXi-7.0bs-16321839-standard
10 : ESXi-7.0bs-16321839-no-tools
11 : ESXi-7.0b-16324942-standard
12 : ESXi-7.0b-16324942-no-tools
13 : ESXi-7.0.1-16850804-standard
14 : ESXi-7.0.1-16850804-no-tools
15 : ESXi-7.0.0-15843807-standard
16 : ESXi-7.0.0-15843807-no-tools
-------------------------------------------
Enter selection: 13
```
2. After downloading the offline bundle, go ahead and create the imageProfile ( ISO).
```
.\ESXi-Customizer-PS-v2.8.1.ps1 -izip  'C:\path\to\where\you\save\ESXi-7.0.1-16850804-standard.zip' -outDir 'C:\path\to\where\you\save\custom-ESXI-ISO' -log 'C:\path\to\where\you\save\logs\ESXi-Customizer.log' -nsc
```
Once the image is created you can upload into the ESXi server and use it as baseline for upgrades.




