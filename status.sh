#!/usr/bin/env nix-shell
#! nix-shell -p nushell
#! nix-shell -i nu

version

def write_new_database [path: string] {
    stor create --table-name statuses --columns {idx: int, date: str, status: str, hide: bool, datestamp: int}
    stor export --file-name $path
}

def create_datastore [] {
    # Check ~/.status is a directory
    # TODO: encapsulate the vars into a function
    let status_app_dir_path = $"($env.HOME)/.status"
    let status_app_db_path = $"($status_app_dir_path)/($env.USER).db"
    let status_app_dir_path_type = $status_app_dir_path | path type
    if $status_app_dir_path_type != "dir" {
        # Something else is at ~/.status
        if $status_app_dir_path_type != "" {
            echo "Your ~/.status is not a directory."
            return
        }

        # ~/.status doesn't exist
        let res = ['Yes' 'No'] | input list "~/.status doesn't exist yet. Initialize the directory for storing status messages?"
        if res == 'No' { return }
        mkdir $status_app_dir_path
        write_new_database $status_app_db_path
    }

    # ~/.status exists as a directory
    let $status_app_db_path_type = $status_app_db_path | path type
    if $status_app_db_path_type != file {
        # ~/.status/user.db is not a file
        if $status_app_db_path_type != "" {
            echo $"Your ~/.status/($env.USER).db is not a file."
            return
        }
        # ~/.status/user.db doesn't exist
        write_new_database $status_app_db_path
    }
}

def write_status [
    status: string
] {
    stor reset
    # TODO: encapsulate the vars into a function
    let status_app_dir_path = $"($env.HOME)/.status"
    let status_app_db_path = $"($status_app_dir_path)/($env.USER).db"
    stor import --file-name $status_app_db_path
    let db = (stor open).statuses
    let now = date now
    let new_id = ([...$db.idx -1] | math max) + 1
    let new_date = $now | format date "%A, %b %d, %Y"
    let new_status = $status
    let new_hide = false
    let new_datestamp = $now | format date "%Y%m%d%H%M%S"
    stor insert --table-name statuses --data-record {idx: $new_id, date: $new_date, status: $new_status, hide: $new_hide, datestamp: $new_datestamp}
    mv --force $status_app_db_path $"($status_app_db_path).backup"
    stor export --file-name $status_app_db_path
}

def main [
    status_message?: string # Your status message to post
] {
    stor reset

    create_datastore

    let status_message = if ($status_message == null) {
        input "New status: "
    } else {
        $status_message
    }

    write_status $status_message
}