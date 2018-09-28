output "filename" {
  value = "${data.archive_file.lambda_zip.output_path}"
}
