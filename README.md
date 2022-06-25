# About
ZPAQ is an open source command line archiver for Windows and Linux. It uses a journaling or append-only format which can be rolled back to an earlier state to retrieve older versions of files and directories (https://en.wikipedia.org/wiki/ZPAQ).

Website: http://mattmahoney.net/dc/zpaq.html

# Description
This system is intended for incremental archiving and long-term storage of archives of directories (databases) and verification of created archives in Windows OS.

The system includes:
- Directory with "zpaq" application
- Main script "zpaq-backup.cmd"
- File containing a list of databases "dbsList.txt"
- Dynamically created directories:
  - dbs_backup to store created archives
  - dbs_extracted_for_check to extract and check generated archives
  - dbs_log for logging and backup status

# Installation
- On the server (Windows OS) where the backup system will be used:
  - Fill in the list of directories (bases) for backup (absolute paths are required) in the dbsList.txt file. Example:
    ```
    d:\tmp\dbs\db01
    d:\tmp\dbs\db02
    d:\tmp\dbs\db03
    ```
  - Change the paths to directories, files and utilities in the paths section of the backup-zpaq.cmd file
  - Run backup-zpaq.cmd

# Work algorithm
- The zpaq-backup.cmd script gets a list of directories (bases) from the "dbsList.txt" file
- Actions are performed for each directory:
  - File "checkMarker.txt" is written to the directory, containing the current date in format **YYYY-mm-dd**
  - Directory is archived along the path dbs_backup\\!dbName!\ with the archive name !dbName!_???.zpaq, where ??? - sequence number of the archive (001 - full archive, the following ones are incremental)
  - Upon completion of the archiving, the status of the operation is written to the dbArchStatus variable (**-ARCH_OK-** | **-ARCH_FAIL-**)
  - The file checkMarker.txt is removed from the directory
  - The archive is extracted along the path dbs_extracted_for_check\\!dbName!
  - Upon completion of the extraction, the status of the operation is written to the dbExtrStatus variable (**-EXTRACT_OK-** | **-EXTRACT_FAIL-**)
  - The dbs_extracted_for_check\\!dbName!\checkMarker.txt file is checked to see if it contains the current date in **YYYY-mm-dd** format. As a result, dbCheckMarkerStatus is set to (**-CHECKMARKER_OK-** | **-CHECKMARKER_FAIL-**)
  - A line like this is written to the backup logging file dbs_log\dbsBackupLog.txt:
    ```
    d:\tmp\dbs\!dbName! : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
    ```

- As a result, the following structure is created in the dbs_log\dbsBackupLog.txt file:
```
d:\tmp\dbs\db01 : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
d:\tmp\dbs\db02 : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
d:\tmp\dbs\db03 : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
```

- Checks for the presence of a sequence of characters in the dbs_log\dbsBackupLog.txt file (**_OK-** | **_FAIL-**)
- Depending on the result, **OK** or **FAIL** is written to the final backup status file dbs_log\dbsBackupStatus.txt
