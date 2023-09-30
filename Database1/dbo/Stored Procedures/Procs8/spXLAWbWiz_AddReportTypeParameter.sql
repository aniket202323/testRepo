-- spXLAWbWiz_AddReportTypeParameter() insert or update Report_Type_Parameters Table
-- Modified from spRS_AddReportTypeParameter: mt/10-23-2002
--
CREATE PROCEDURE dbo.spXLAWbWiz_AddReportTypeParameter
 	   @Report_Type_Id  Int
 	 , @RP_Name         Varchar(50)
 	 , @Default_Value   Varchar(7000)
 	 , @Optional        SmallInt
AS
DECLARE @RP_Id                      Int
DECLARE @Existing_RTP_Id            Int
DECLARE @@Report_Id                 Int
DECLARE @Return_ID                  Int
 	 --Needed for ReturnStatus
DECLARE @Return_Status              Int
DECLARE @Return_Status_NothingDone  TinyInt
DECLARE @Return_Status_Insert       TinyInt
DECLARE @Return_Status_Update       TinyInt
 	 --Define return status
SELECT @Return_Status_NothingDone  = 0
SELECT @Return_Status_Insert       = 1
SELECT @Return_Status_Update       = 2
SELECT @Return_Status = -1  	 --Initialize
SELECT @Return_ID = -1       --Initialize
CREATE TABLE #t(Report_Id Int)
INSERT INTO #t(Report_Id) SELECT Report_Id FROM Report_Definitions WHERE Report_Type_Id = @Report_Type_Id
-- Get @RP_Id for the passed in Parameter (@RP_Name )
SELECT @RP_Id = RP_Id FROM Report_Parameters WHERE RP_Name = @RP_Name
If @RP_Id Is NULL  --parameter with @RP_Name does not exist
  BEGIN
    SELECT @Return_ID = 0 --return a phony value of RTP_Id
    SELECT @Return_Status = @Return_Status_NothingDone
  END
Else --@RP_Id NOT NULL, passed in parameter exists
  BEGIN
    -- Check if Parameter already exists for this report type
    SELECT @Existing_RTP_Id = RTP_Id FROM Report_Type_Parameters WHERE Report_type_Id = @Report_Type_Id AND RP_Id = @RP_Id
    If @Existing_RTP_Id Is NOT NULL  --it exists, do update
      BEGIN
        Update Report_Type_Parameters Set Default_Value = @Default_Value, Optional = @Optional
        WHERE RTP_Id = @Existing_RTP_Id
        SELECT @Return_ID = @Existing_RTP_Id
        SELECT @Return_Status = @Return_Status_Update
      END
    Else --@Existing_RTP_Id Is NULL, do Insert
      BEGIN
        INSERT INTO Report_Type_Parameters(Report_Type_Id, RP_Id, Default_Value, Optional) VALUES(@Report_Type_Id, @RP_Id, @Default_Value, @Optional)
        SELECT @Return_ID = Scope_Identity()
        -- Add To Report Def --
        DECLARE MyCursor INSENSITIVE CURSOR FOR (SELECT Report_Id FROM #t) FOR READ ONLY
        OPEN MyCursor                                    
TOP_OF_LOOP:
        FETCH NEXT FROM MyCursor INTO @@Report_Id 
        If (@@Fetch_Status = 0)
          BEGIN
            EXEC spRS_AddReportDefParam @@Report_Id, @RP_Name, @Default_Value
            GOTO TOP_OF_LOOP
          END
        Else -- Nothing Left To Loop Through
          GOTO END_OF_LOOP
        --EndIf                          
END_OF_LOOP:
        CLOSE MyCursor
        DEALLOCATE MyCursor
        SELECT @Return_Status = @Return_Status_Insert
      END
    --EndIf:@Existing_RTP_Id NOT NULL
  END -- @RP_Id is not null
--EndIf @RP_Id Is NOT NULL
SELECT [ReturnStatus] = @Return_Status, [Return_Id] = @Return_ID
DROP TABLE #t
