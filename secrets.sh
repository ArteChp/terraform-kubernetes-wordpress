#!/bin/bash

export TF_VAR_mysql_root_pass=$(pass mysql-admin)
export TF_VAR_mysql_wp1_pass=$(pass mysql-wp1)
export TF_VAR_mysql_wp2_pass=$(pass mysql-wp2)
export TF_VAR_mysql_wp3_pass=$(pass mysql-wp3)
export TF_VAR_mysql_wp4_pass=$(pass mysql-wp4)


