# 1. Base Image
# Começamos com a base do Jazzy e faremos tudo nela
FROM ros:jazzy-ros-base

# 2. Configurar o Ambiente
SHELL ["/bin/bash", "-c"]

# 3. Instala todas as dependências de build (compiladores, git, etc.)
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-colcon-common-extensions \
    python3-colcon-meson \
    python3-pip \
    python3-ply \
    python3-rosdep \
    python3-jinja2 \
    && rm -rf /var/lib/apt/lists/*


# 4. Cria o workspace e define como diretório de trabalho
RUN mkdir -p /camera_ws/src
WORKDIR /camera_ws/src

# 5. Clona os repositÃ³rios (O "Plano B" do README)
# OpÃ§Ã£o B: O fork do Raspberry Pi
RUN git clone https://github.com/raspberrypi/libcamera.git
# O nó da câmera
RUN git clone https://github.com/christianrauch/camera_ros.git

# 6. Inicializa o rosdep para instalar dependências
WORKDIR /camera_ws
RUN rosdep init || echo "rosdep jÃ¡ inicializado"
RUN rosdep update

# 7. Instala as dependÃªncias dos nossos pacotes
# (Pulando 'libcamera' pois estamos compilando ele)
RUN source /opt/ros/jazzy/setup.bash && \
    sudo apt update && \
    rosdep install -y --from-paths src --ignore-src --rosdistro jazzy --skip-keys=libcamera

# 8. Compila o workspace inteiro
# Esta Ã© a etapa que vai demorar.
RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --event-handlers=console_direct+ --symlink-install

# 9. Configura o Entrypoint
# Copia o entrypoint que sabe sobre o /camera_ws
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

# 10. Define o diretÃ³rio de volta para / (opcional, boa prÃ¡tica)
WORKDIR /