# Outputs for Firestore usage
output "FirestoreInfo" {
  value = {
    project_id             = local.my_gcp_project_id
    database_id            = google_firestore_database.tofu_example_firestore_db.name
    location_id            = google_firestore_database.tofu_example_firestore_db.location_id
    firestore_api_endpoint = "https://firestore.googleapis.com/v1/projects/${local.my_gcp_project_id}/databases/(default)/documents"
  }
  description = "Information needed to connect and use the Firestore database, including project ID, database ID, location, and API endpoint."
}
