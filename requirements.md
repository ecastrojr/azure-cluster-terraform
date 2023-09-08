# Requirements

- O cluster será Docker Swarm, tendo 1 master e 2 workers;

- As máquinas masters deverão ter 4 cores e 8GB de RAM, as máquinas workers deverão ter 2 cores e 4GB de RAM;

- A infra deve ser fléxivel para que eu possa aumentar o número de workers e masters;

- Os resources do cluster deverão ser configurados tendo o nome da minha empresa (Codions) como parte, use padrões de nomes adequados;

- Todas as máquinas deverão ter o Ubuntu 22.04 LTS instalado;

- O usuário admin de todas as máquinas deverá se chamar codions e a senha deverá ser ``C0d1o#4s%``;

- Em todas as máquinas, quero ter acesso via SSH para o usuário admin e root;

- Eu quero que todas as portas na máquina master estejam liberadas;

- As máquinas deverão ter um disco compartilhado entre elas, com 160GB de espaço. O disco deverá ser montado em /mnt/shared;

- As configurações repetitivas ou sensíveis devem ser colocadas em variáveis em um arquivo separado (variables.tf);

- Execute o comando em todas máquinas como root: ufw allow 80,443,3000,996,7946,4789,2377/tcp; ufw allow 7946,4789,2377/udp;

- Quero que este cluster seja configurado com o docker em todos os nós (curl -fsSL get.docker.com | sh);

- O CapRover deve ser instalado apenas nos masters (docker run -p 80:80 -p 443:443 -p 3000:3000 -e ACCEPTED_TERMS=true -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover)