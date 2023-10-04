#!/bin/bash

set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps
dbt seed --target "$db" --full-refresh
dbt run --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{using_account_history_mode_active_records: true, using_opportunity_history_mode_active_records: true, using_user_role_history_mode_active_records: true, using_user_history_mode_active_records: true, salesforce__user_role_enabled: false}' --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{salesforce__account_history_enabled: true, salesforce__contact_history_enabled: true, salesforce__event_history_enabled: true, salesforce__lead_history_enabled: true, salesforce__opportunity_history_enabled: true, salesforce__task_history_enabled: true, salesforce__user_history_enabled: true, salesforce__user_role_history_enabled: true}' --target "$db" --full-refresh
dbt test --target "$db"
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
