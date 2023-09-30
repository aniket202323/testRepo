Create Procedure dbo.spBF_CreateModel210
  @PUId           	 int,
  @TreeName 	  	  	 nvarchar(100),
  @UserId  	  	  	 int,
  @RunningTag 	  	 nvarchar(100),
  @RunningScript 	 nvarchar(max),
  @FaultTag 	  	  	 nvarchar(100),
  @FaultSctipt 	  	 nvarchar(max),
  @EcId 	  	  	  	 Int  OUTPUT
AS
IF @RunningTag Not Like 'PT:%' SELECT @RunningTag = 'PT:' + @RunningTag
IF @FaultTag Not Like 'PT:%'   SELECT @FaultTag = 'PT:' + @FaultTag
IF @RunningScript IS Null
BEGIN
 	 SELECT @RunningScript = 'If RUNTAG = "RUNNING" Then
 	 Running = True
 Else
 	 Running = False
 End If'
END
IF @FaultSctipt IS Null
BEGIN
 	 SELECT @FaultSctipt = 'Fault = FaultTag'
END
DECLARE @ModelDesc nVarChar(100)
DECLARE @ECVID Int
DECLARE @ECVDID Int
DECLARE @EDModelId Int
DECLARE @EDFieldId Int
DECLARE @TreeId Int
SET @ModelDesc = 'EfficiencyAnalyzer Faults Occur On Single Location'
DECLARE @CommentId Int
--Create Config
SELECT @EDModelId = ED_Model_Id from ED_Models  where Model_Num  = 210
EXECUTE  spEMEC_CreateNewEC @PUID,0,@ModelDesc,2,NULL,@UserId,@ECId output,@CommentId output
UPDATE Comments Set Comment_Text = 'Auto Created Based on DownTime Class attatchment'
 	 WHERE Comment_Id = @CommentId
UPDATE Comments Set Comment = 'Auto Created Based on DownTime Class attatchment'
 	 WHERE Comment_Id = @CommentId
-- Add Model 	 
EXECUTE spEMSEC_UpdateEventConfiguration @ECId,210,@UserId
IF @TreeName IS Not Null
BEGIN
 	 SELECT @TreeId = Tree_Name_Id from Event_Reason_Tree WHERE Tree_Name = @TreeName
END
IF @TreeId Is Null
BEGIN
 	 SELECT @TreeId = MIN(Tree_Name_Id) from Event_Reason_Tree WHERE Tree_Name like '%DownTime%'
END 	 
EXECUTE spEMSEC_PutEventConfigInfo     @PUID,2,@TreeId,NULL,0,1,1
EXECUTE spEMSEC_PutECData    3,@ECId,@PUID,'0',0,NULL,@UserId,@ECVID output
SET @ECVID = Null 
SET @EDFieldId = Null
SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 4
EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'0',1,NULL,@UserId,@ECVID output
SET @ECVID = Null 
SET @EDFieldId = Null
SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 5
EXECUTE spEMSEC_PutECData @EDFieldId,@ECId,@PUID,'1',1,NULL,@UserId,@ECVID output
SET @ECVDID = Null 
SET @EDFieldId = Null
SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 2
EXECUTE spEMSEC_PutInputData     @ECId,@PUID,'RUNTAG',1,@RunningTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
SET @ECVDID = Null 
EXECUTE spEMSEC_PutInputData @ECId,@PUID,'FAULTTAG',1,@FaultTag,1,12,0,0,@EDFieldId,@UserId,@ECVDID output
SET @ECVID = Null
SET @EDFieldId = Null
SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 1
EXECUTE spEMSEC_PutECData   @EDFieldId,@ECId,@PUID,@RunningScript,1,NULL,@UserId,@ECVID output
SET @ECVID = Null 
SET @EDFieldId = Null
SELECT @EDFieldId = ED_Field_Id from ED_Fields where ED_Model_Id = 30 and Field_Order = 3
EXECUTE spEMSEC_PutECData  @EDFieldId,@ECId,@PUID,'Fault = FaultTag',1,NULL,@UserId,@ECVID output
