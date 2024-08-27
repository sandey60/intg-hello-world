# Docker image build file for extending the Cumulator micro integrator with additional Carbon Apps 
ARG baseImage

FROM ${baseImage}
COPY ./cars /home/dtcloud/cars
RUN cd /home/dtcloud && \
    chown -R dtcloud:dtcloud /home/dtcloud/cars
