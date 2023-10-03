# MONAN - Model for Ocean-laNd-Atmosphere PredictioN

### *Quick Start para o ambiente Egeon v0.1.0*

    Grupo de Computação Científica (GCC)
    Divisão de Modelagem Numérica do Sistema Terrestre - DIMNT  
    Coordenação-Geral de Ciências da Terra - CGCT
    
    2 de Outubro de 2023



## 1. Introdução

Este manual descreve um procedimento rápido para o desenvolvedor compilar e executar o MONAN (atualmente código MPAS 8.0.1 puro) no ambiente de supercomputação Egeon. 

O procedimento foi desenvolvido com base no manual [1] disponibilizado pelo Grupo de Avaliação de Modelos (GAM), onde são melhor detalhados os passos aqui descritos, e com base no manual do MPAS 8.0.1 e suas referências no site [2].

As seguintes seções introduzem o ambiente Egeon, os artefatos utilizados e descrevem como executar o passo a passo para obter o código do MONAN em um branch pessoal para trabalho para compilar e executar o modelo de forma automatizada.


### 1.1 Ambiente Egeon

O ambiente Egeon é formado por 33 nós com 2 sockets AMD EPYC 7H12 64-Core Processor, ou 128 cores por nó, com 512GB de memória. A fila denominada “batch” (até 16 nós) é exclusiva para o desenvolvimento do MONAN.
Dentre os recursos atualmente instalados como módulos, apenas alguns são necessários para a execução do passo a passo, como exemplo o gnu9/9.4.0 e mpich-4.0.2-gcc-9.4.0-gpof2pv, para compilar e executar o MONAN. Todos os módulos necessários e bibliotecas pré-compiladas são carregados no passo a passo dos scripts.


### 1.2 MONAN (MPAS 8.0.1) e caso de uso

O código utilizado como base para o MONAN foi extraído da versão 8.0.1 do MPAS. Atualmente o MONAN é o próprio MPAS, que está versionado em https://github.com/monanadmin/MONAN-Model .

O caso de uso deste manual utiliza uma configuração de 24km do MPAS sobre o evento de UTC de 1º de Janeiro de 2021. Mais informações sobre o caso de uso utilizado nesse passo a passo podem ser verificadas em [1].


### 1.3 Overview do passo a passo
O passo a passo descrito a seguir é formado pelos seguintes passos:

1. Obtenção da versão pessoal de desenvolvimento do MONAN:

    Neste passo se inicia uma versão de desenvolvimento do MPAS em sua área de trabalho na Egeon à partir do repositório de desenvolvimento do MONAN. 

    **Atenção**: Neste local deverão ser efetuadas as mudanças desejadas no modelo e em seguida a alteração deverá ir para o repositório do GitHub. No passo 5, as mudanças são obtidas em outro local, para compilar o modelo. Este passo só deve ser executado uma vez.

2. Obtenção dos scripts do passo a passo

    Este passo faz o download dos scripts necessários para a execução completa do passo a passo. Este passo só deve ser executado uma vez. Estrutura dos diretórios e arquivos dos scripts:

~~~
    .
    ├── README.md
    └── egeon
        ├── 1.install_spack.bash
        ├── 2.install_wps.bash
        ├── 3.install_monan.bash
        ├── 4.pre_monan.bash
        ├── 5.monan.bash
        ├── 6.pos_monan.bash
        ├── MPAS_ori
        │   └── testcase
        │       └── scripts
        │           ├── link_grib.csh
        │           ├── ngrid2latlon.sh
        │           ├── prec.gs
        │           ├── run_mpas_gnu_egeon.bash
        │           └── static.sh
        ├── README.md
        └── load_monan_app_modules.sh
~~~

A pasta egeon será a raiz do passo a passo. Com a evolução dos passos, será criada a pasta MPAS nesta estrutura, onde serão armazenados todos dados e executáveis para o passo a passo, detalhados nos passos a seguir.

3. Instalação do Spack para compilar o WPS.

    Aqui se instala o gerenciador de pacotes Spack, que serve apenas para facilitar a instalação do WPS. Este passo só deve ser executado uma vez.

4. Instalar o WPS (para o pré)

    O WPS é necessário para o pré-processamento requerido para o modelo. Este passo só deve ser executado uma vez.

5. Instalar o MONAN

    Este passo instala o MONAN à partir do seu repositório de desenvolvimento pessoal (fork).

    **Atenção**: Neste passo, o local de obtenção do repositório serve apenas para compilar o modelo. O diretório de trabalho para alterar o modelo está descrito no passo 1.

6. Executar o pré do MONAN

    Neste passo se executa todo o pré-processamento necessário para executar o MONAN. Este passo deve ser executado novamente se as condições iniciais ou de contorno forem alteradas.

7. Executar o MONAN

    Aqui executa-se o MONAN, utilizando os dados e executáveis dos passos anteriores.

8. Executar o pós do MONAN

    Neste passo, o pós-processamento do MONAN é executado, onde os arquivos de saída do MPAS são convertidos para uma grade regular e uma figura de visualização é gerada.

    **Atenção**:
    É sugerida a utilização do comando nohup antes de todos os passos que executam scripts, para evitar ter que refazer todos os passos em caso de falha. Este comando continua executando mesmo que caia a conexão. Exemplo: “nohup ./1.install_spack.bash &” Este comando coloca a saída no arquivo nohup.out. Para acompanhar o progresso, faça “tail -f nohup.out”.



## 2. Passo a Passo

Os comandos estritamente necessários a serem executados no passo a passo estão demarcados com uma caixa de seleção e dentro de uma caixa, como o exemplo abaixo:

~~~
[ ] comando a ser executado
~~~
~~~
Outros comandos, como de validação, ou resultados de terminal estão descritos como este, em uma caixa
~~~

Ao final de cada passo, é sugerido um procedimento de **Validação** do passo. Se não for possível concluir o passo, não será possível executar os passos seguintes e será preciso investigar a causa.


### 2.1 Obtenção da versão pessoal de desenvolvimento do MONAN

Passos obrigatórios para a execução dos scripts:
* Entrar na página https://github.com/monanadmin/MONAN-Model 
* Executar o fork. 

**Validação**: Fork criado na sua conta no GitHub

Passos opcionais (necessários para alterações no modelo):
Copiar o endereço do Git do seu fork, por exemplo: https://github.com/meusuario/MONAN-Model.git :

- Após logar-se no ambiente Egeon, entrar na sua área de trabalho do beegfs:
~~~
cd /mnt/beegfs/$USER
~~~

- Baixar o código com os scripts gerenciados no GitHub usando o Git com o endereço do GitHub do seu fork :
~~~
git clone https://github.com/<SEU USUÁRIO>/<SEU REPOSITÓRIO MONAN NO GitHub>
~~~

**Validação**: neste momento, você terá sua versão do modelo para alteração em: `/mnt/beegfs/$USER/<SEU REPOSITÓRIO MONAN NO GitHub>`


### 2.2 Obtenção dos scripts do passo a passo

Após o logon no ambiente Egeon, entrar na sua área de trabalho do beegfs:
~~~
[ ] cd /mnt/beegfs/$USER
~~~

Baixar o código com os scripts gerenciados no GitHub usando o git:

~~~
[ ] git clone https://github.com/monanadmin/MONAN-scripts.git
~~~

Observe que não é necessário o fork nesse passo, pois provavelmente o desenvolvedor não irá trabalhar com o código destes scripts, apenas o usarão.

**Validação**: neste momento, você deverá ter sua versão dos scripts para seguir o passo a passo em `/mnt/beegfs/$USER/MONAN-scripts`


### 2.3. Scripts – passo 1: Instalação do Spack para compilar o WPS

Entrar na sua área de download os script, subpasta egeon:
~~~
[ ] cd /mnt/beegfs/$USER/MONAN-scripts/egeon
~~~

Executar a instalação:
~~~
[ ] ./1.install_spack.bash
~~~

Após a instalação, obtêm-se a seguinte estrutura:
~~~
.
└── egeon
    ├── spack_wps
    …
~~~

**Validação**: Execute o comando `spack`. Se o comando for aceito, a instalação foi executada corretamente.


### 2.4. Scripts – passo 2: Instalar o WPS (para o pré)

Execute o comando abaixo para carregar o Spack, sugerido após a instalação no passo 1:
~~~
[ ] source spack_wps/env_wps.sh
~~~

Executar a instalação:
~~~
[ ] ./2.install_wps.bash
~~~

**Validação**: após a instalação, o local de instalação WPS pode ser encontrado usando o seguinte comando: 
~~~
spack location -i wps@4.3.1%gcc@9.4.0
~~~
onde se encontrará por exemplo o executável ungrib, necessário para o pré-processamento do modelo.


### 2.5. Scripts – passo 3: Instalar o MONAN

No comando abaixo utilize a URL do seu fork (Veja passo 2.1) no parâmetro, como no padrão abaixo:
~~~
[ ] ./3.install_monan.bash https://github.com/<MEUUSUARIO>/<MONAN-Model.git>
~~~

Caso a URL do seu fork não seja encontrada no GitHub, ou caso você tenha alterado seu fork para ser privado (o padrão é público), será solicitado o usuário e senha. Se a URL não existir ou o usuário e senha estejam errados, a seguinte mensagem será emitida:
~~~
“An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.”
~~~

Caso tudo tenha ocorrido bem, execute o comando sugerido no terminal ao final da execução do script para efetivamente compilar o modelo, semelhante ao comando abaixo:
~~~
[ ] cd MPAS/src/MPAS-Model_v8.0.1_egeon.gnu940 && source make.sh && cd ../../..
~~~

**Validação**: Ao final da execução do script, a mensagem abaixo é emitida no terminal para confirmar que foram gerados os executáveis, e seguir com os próximos passos.
~~~
!!! Files init_atmosphere_model and atmosphere_model generated Successfully in … !!!
~~~


### 2.6. Scripts – passo 4: Executar o pré do MONAN

Execute os comando abaixo:
~~~
[ ] source ./spack_wps/env_wps.sh
[ ] ./4.pre_monan.bash
~~~


**Validação**: após a execução, verifique se foram gerados os arquivos abaixo:
~~~
./MPAS/testcase/runs/ERA5/static/x1.1024002.static.nc 
./MPAS/testcase/runs/ERA5/2021010100/wpsprd/FILE:2021-01-01_00
./MPAS/testcase/runs/ERA5/2021010100/wpsprd/FILE2:2021-01-01_00
./MPAS/testcase/runs/ERA5/2021010100/wpsprd/FILE3:2021-01-01_00
./MPAS/testcase/runs/ERA5/2021010100/wpsprd/GEO:1979-01-01_00
./MPAS/testcase/runs/ERA5/2021010100/wpsprd/LSM:1979-01-01_00
./MPAS/testcase/runs/ERA5/2021010100/x1.1024002.init.nc
~~~


### 2.7. Scripts – passo 5: Executar o MONAN

Execute:
~~~
[ ] ./5.monan.bash
~~~

**Validação**: após a execução, verifique se foram gerados os arquivos abaixo em `./MPAS/testcase/runs/ERA5/2021010100/mpasprd`:
~~~
diag.2021-01-01_08.00.00.nc
diag.2021-01-01_09.00.00.nc
diag.2021-01-01_10.00.00.nc
    … até:
diag.2021-01-02_00.00.00.nc

history.2021-01-01_00.00.00.nc
history.2021-01-01_03.00.00.nc
history.2021-01-01_06.00.00.nc
    … até:
history.2021-01-02_00.00.00.nc

E o arquivo gerado no pré:
x1.1024002.init.nc
~~~


### 2.8. Scripts – passo 6: Executar o pós do MONAN
~~~
[ ] ./6.pos_monan.bash
~~~

**Validação**: Usando os comandos abaixo, verifique que a figura foi gerada e que se parece com a figura mais abaixo:

~~~
[ ] module load imagemagick-7.0.8-7-gcc-11.2.0-46pk2go
[ ] display ./MPAS/testcase/runs/ERA5/2021010100/postprd/MPAS.png
~~~

![image](https://github.com/monanadmin/MONAN-scripts/assets/6113640/0bfa7214-2ed0-4af0-b3c4-969053635e17)


## REFERÊNCIAS


[1] - Model for Prediction Across Scales-Atmosphere (MPAS-A) on INPE’s EGEON System User’s Guide. Julio P R Fernandez  et al., 2023 . (Draft)


[2] - https://mpas-dev.github.io/ , de onde se encontra as public releases, referências para o repositório GitHub e manual.
