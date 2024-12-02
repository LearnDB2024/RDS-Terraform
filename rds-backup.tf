data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup_default_service_role" {
  name               = "AWSBackupDefaultServiceRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup_service_role_for_backup_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_default_service_role.name
}

# backup.tf (continued)
resource "aws_backup_vault" "rds_backup_vault" {
  name        = "rds-backup-vault"
 ## kms_key_arn = var.aws_kms_key_arn
}


# backup.tf
resource "aws_backup_plan" "rds_instance_plan" {
  name = "rds-instance-daily-backup"

  rule {
    rule_name                = "rds-instance-daily-backup-rule"
    target_vault_name        = aws_backup_vault.rds_backup_vault.name
    schedule                 = "cron(0 12 * * ? *)"
    enable_continuous_backup = true

    lifecycle {
      delete_after = 2
    }
  }
}

resource "aws_backup_selection" "rds_instance_selection" {
  iam_role_arn = aws_iam_role.backup_default_service_role.arn
  name         = "rds-instance-daily-backup-selection"
  plan_id      = aws_backup_plan.rds_instance_plan.id

  resources = [
    module.db.db_instance_arn
  ]
}