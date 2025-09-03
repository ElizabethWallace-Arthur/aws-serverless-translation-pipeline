# AWS Serverless Translation Pipeline

A serverless translation pipeline implemented on AWS, leveraging S3, Lambda, Amazon Translate, and Terraform to automate multilingual text processing in a scalable and cloud-native architecture.


## Project Structure
```bash
CapstoneProject/
├── lambda/              # Lambda function source code
│   └── lambda_function.py
├── sample_json/         # Sample JSON input files
│   └── translate.json
├── terraform/           # Terraform configuration files
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── lambda_function.zip
```


## Architecture
1. A JSON file is uploaded to the **Source S3 Bucket**.

```json
{
  "text": "Hello, what is your general overview of my capstone project?",
  "source_lang": "en",
  "target_lang": "fr"
}
```

2. The upload event triggers an **AWS Lambda Function**.

3. Lambda reads the file, extracts the text, and calls **Amazon Translate**.

4. The translated text is stored as a new JSON file in the **Target S3 Bucket**.
```json
{
  "TranslatedText": "Bonjour, quel est votre aperçu général de mon projet de synthèse?",
  "SourceLanguageCode": "en",
  "TargetLanguageCode": "fr"
}
```

5. Logs and execution details are monitored via **Amazon CloudWatch**.

6. *Figure 1.1 – Architectural Diagram*



## Deployment with Terraform

Initialize Terraform
```bash
terraform init
```

Preview the plan
```bash
terraform plan
```

Apply the changes
```bash
terraform apply
```

### This will create:

2 S3 buckets (source + target)

1 Lambda function

IAM roles and permissions

Event notification triggers



## Conclusion

This project highlights the power of AWS serverless architecture for real-time document translation. It demonstrates how S3, Lambda, and Translate can work together seamlessly, all automated through Terraform.


## Future Improvements

Add a frontend webpage for user input and display results.

Support multiple files and larger documents.

Integrate with DynamoDB for storing translation history.

Add Cognito authentication for user access control.


👩🏽‍💻 Author


Elizabeth Wallace Arthur

Capstone Project – Azubi Africa
