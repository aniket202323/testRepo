CREATE PROCEDURE dbo.spServer_EMgrAddGradeChange
@ProdId int,
@PUId int,
@Confirmed int,
@StartTime datetime,
@StartId int OUTPUT,
@ProdCode nVarChar(30) OUTPUT,
@ModifiedStart datetime OUTPUT,
@ModifiedEnd datetime OUTPUT,
@Success int OUTPUT
AS
Declare
  @Result int,
  @EndTime datetime
Select @Success = 0
Select @EndTime = NULL
Select @ProdCode = ''
Select @StartId = NULL
Execute @Result = spServer_DBMgrUpdGrade2 
 	 @StartId OUTPUT,
 	 @PUId,
 	 @ProdId,
 	 @Confirmed,
 	 @StartTime     OUTPUT,
 	 0,
 	 6,
 	 NULL,
 	 NULL,
 	 @EndTime       OUTPUT,
 	 @ProdCode  	 OUTPUT,
 	 0,
 	 @ModifiedStart OUTPUT,
 	 @ModifiedEnd OUTPUT
If ((@Result = 1) Or (@Result = 2)) And (@StartId Is Not NULL) And (@ProdCode <> '')
  Select @Success = 1
