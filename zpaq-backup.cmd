@echo OFF

REM
REM ZPAQ-BACKUP - archiving multiple directories with unpacking for checking
REM by Cless
REM
REM Requirements:
REM * change list of bases for backup (with full paths) in the file dbsList.txt. it must be filled in manually
REM * change var's paths in "paths" section
REM


REM ---
REM VARS
REM ---

REM paths
SET rootDir=d:\tmp\backup-zpaq
SET zpaq=%rootDir%\zpaq\zpaq64.exe
REM SET dbsDir=%rootDir%\dbs
SET dbsBackupDir=%rootDir%\dbs_backup
SET dbsExtractedForCheckDir=%rootDir%\dbs_extracted_for_check
SET dbsLogDir=%rootDir%\dbs_log
SET dbsBackupLogFile=%dbsLogDir%\dbsBackupLog.txt
SET dbsBackupStatusFile=%dbsLogDir%\dbsBackupStatus.txt
SET dbsListDir=%rootDir%
SET dbsListFile=%dbsListDir%\dbsList.txt

REM Year
set year=%date:~-4%

REM Month
set month=%date:~3,2%
REM Remove leading space if single digit
if "%month:~0,1%" == " " set month=0%month:~1,1%

REM Day
set day=%date:~0,2%
REM Remove leading space
if "%day:~0,1%" == " " set day=0%day:~1,1%

REM dateCurrent (YYYY-mm-dd)
SET dateCurrent=%year%-%month%-%day%


REM ---
REM COMMON ACTIONS
REM ---

REM create dbsList dir
if not exist "%dbsListDir%" (
    mkdir "%dbsListDir%"
)

REM create log dir
if not exist "%dbsLogDir%" (
    mkdir "%dbsLogDir%"
)

REM delete backup log
if exist "%dbsBackupLogFile%" (
    del /Q /F "%dbsBackupLogFile%"
)

REM delete backup status
if exist "%dbsBackupStatusFile%" (
    del /Q /F "%dbsBackupStatusFile%"
)
    
REM auto get db list and put it to file
REM dir /b "%dbsDir%" > "%dbsListFile%"

REM create array of db names with paths from db list file
setlocal enableDelayedExpansion
set /a i=0
for /F "usebackq delims=" %%A in ("%dbsListFile%") do (
    set /a i+=1
    set "array[!i!]=%%A"
)

REM ---
REM FOR EVERY DB NAME WITH FULL PATH FROM DBSLIST.TXT DO:
REM ---

for /L %%A in (1,1,%i%) do (

    REM get dbNameWithPath from array element
    Set dbNameWithPath=!array[%%A]!

    REM debug
    echo.dbNameWithPath is: !dbNameWithPath!

    REM get db name without path
    for %%A in ("!dbNameWithPath!") do (
        Set dbPath=%%~dpA
        Set dbName=%%~nxA
    )

    REM debug
    echo.dbPath is: !dbPath!
    echo.dbName of db is: !dbName!


    REM ---
    REM ARCH DB
    REM ---
    
    REM delete chk marker
    if exist "!dbNameWithPath!\checkMarker.txt" (
        del /Q /F "!dbNameWithPath!\checkMarker.txt"
    )
    
    REM create chk marker in db
    echo %dateCurrent% > "!dbNameWithPath!\checkMarker.txt"
    
    REM create root dir for db in common backup dir
    if not exist "%dbsBackupDir%\!dbName!" (
        mkdir "%dbsBackupDir%\!dbName!"
    )
    
    REM create dir for db arch status in common dbArchStatus dir
    REM if not exist "%dbsArchStatusDir%\!dbName!\" (
    REM     mkdir "%dbsArchStatusDir%\!dbName!\"
    REM )
        
    REM arch db
    cd /D !dbPath!
    %zpaq% a "%dbsBackupDir%\!dbName!\!dbName!_???.zpaq" "!dbName!"
            
    REM get dbArchStatus
    if "!ERRORLEVEL!" == "0" (
        echo "DB '!dbName!' -ARCH_OK-"
        SET dbArchStatus=-ARCH_OK-
        
        REM put arch status to file
        REM echo OK > "%dbsArchStatusDir%\!dbName!\archStatus.txt"
        
    ) else (
        echo "DB '!dbName!' -ARCH_FAIL-";
        SET dbArchStatus=-ARCH_FAIL-
        
        REM put arch status to file
        REM echo FAIL > "%dbsArchStatusDir%\!dbName!\archStatus.txt"
    )
    
    REM delete chk marker in source db
    if exist "!dbNameWithPath!\checkMarker.txt" (
        del /Q /F "!dbNameWithPath!\checkMarker.txt"
    )
        

    REM ---
    REM EXTRACT DB FOR CHECK
    REM ---
    
    REM create dbsExtractedForCheckDir
    if not exist "%dbsExtractedForCheckDir%" (
        mkdir "%dbsExtractedForCheckDir%"
    )
    
    REM delete every extracted for check db
    if exist "%dbsExtractedForCheckDir%\!dbName!" (
        rmdir /s /q "%dbsExtractedForCheckDir%\!dbName!"
    )        
    
    REM create dir for db extr status in common dbExtrStatus dir
    REM if not exist "%dbsExtrStatusDir%\!dbName!\" (
    REM     mkdir "%dbsExtrStatusDir%\!dbName!\"
    REM )
    
    REM extract db
    cd /D "%dbsBackupDir%\!dbName!\"
    %zpaq% x "!dbName!_???.zpaq" -force -to "%dbsExtractedForCheckDir%"

    REM get dbExtrStatus
    if "!ERRORLEVEL!" == "0" (
        echo "DB '!dbName!' -EXTRACT_OK-"
        SET dbExtrStatus=-EXTRACT_OK-

        REM put extr status to file
        REM echo OK > "%dbsExtrStatusDir%\!dbName!\extrStatus.txt"
    ) else (
        echo "DB '!array[%%A]!' -EXTRACT_FAIL-"
        SET dbExtrStatus=-EXTRACT_FAIL-
        
        REM put extr status to file
        REM echo FAIL > "%dbsExtrStatusDir%\!dbName!\extrStatus.txt"
    )

    REM find currentdate in db marker file
    type "%dbsExtractedForCheckDir%\!dbName!\checkMarker.txt" | findstr "%dateCurrent%"

    REM if
    if "!ERRORLEVEL!" == "0" (
        echo "DB '!dbName!' -CHECKMARKER_OK-"
        SET dbCheckMarkerStatus=-CHECKMARKER_OK-
    ) else (
        echo "DB '!dbName!' -CHECKMARKER_FAIL-"
        SET dbCheckMarkerStatus=-CHECKMARKER_FAIL-
    )

    REM write backup log
    echo.!dbNameWithPath! : !dbArchStatus! !dbExtrStatus! !dbCheckMarkerStatus!>> %dbsBackupLogFile%

    REM put dbName without path to file
    REM echo !dbName! >> %dbsListWithoutPathFile%
)

REM find BACKUP_FAIL in backup log file
type "%dbsBackupLogFile%" | findstr "_FAIL-"

REM IF there's BACKUP_FAIL in log file - write FAIL into status file
if "!ERRORLEVEL!" == "0" (
    echo "-BACKUP_FAIL-"

    REM write OK backup status
    echo.FAIL> %dbsBackupStatusFile%
) else (

    REM find BACKUP_OK in backup log file
    type "%dbsBackupLogFile%" | findstr "_OK-"

    REM IF there's BACKUP_OK in log file - write OK into status file
    if "!ERRORLEVEL!" == "0" (
        echo."-BACKUP_OK-"

        REM write FAIL backup status
        echo.OK> %dbsBackupStatusFile%
    ) else (
    echo."-BACKUP_FAIL-"

    REM backup log
    echo.FAIL> %dbsBackupStatusFile%
    )
)
