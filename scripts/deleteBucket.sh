#!/bin/bash
aws s3 rb --force s3://${TF_VAR_emailidsan}-terraform-bucket
