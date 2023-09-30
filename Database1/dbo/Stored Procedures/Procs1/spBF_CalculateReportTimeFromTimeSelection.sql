--
Create Procedure [dbo].[spBF_CalculateReportTimeFromTimeSelection](@EquipmentList  nVarChar(100) , @EquipmentType int,   @TimeSelection Int,@StartTime DateTime Output,@EndTime DateTime Output,@CappCurrentTime Int = 1)
AS 
BEGIN
  	 /*
 	  	 @TimeSelection = 1 /* Current Day  */
 	  	 @TimeSelection = 2 /* Prev Day     */
 	  	 @TimeSelection = 3 /* Current Week */
 	  	 @TimeSelection = 4 /* Prev Week    */
 	  	 @TimeSelection = 5 /* Next Week    */
 	  	 @TimeSelection = 6 /* Next Day     */
 	  	 @TimeSelection = 7 /* User Defined  Max 30 days*/
 	  	 @TimeSelection = 8 /* Current Shift    */
 	  	 @TimeSelection = 9 /* Previous Shift   */
 	  	 @TimeSelection = 10 /* Next Shift      */
 	 */
DECLARE @Departments Table (DeptId 	 Int)
DECLARE @Units Table (PUId 	 Int)
DECLARE @Lines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50))
Declare @LineID nvarchar(50) = NULL 
SET @EquipmentList = NULL;
if (@EquipmentList is not null)
BEGIN
 	 IF @EquipmentType = 3  -- Department
 	 BEGIN
 	  	 INSERT INTO @Departments(DeptId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Departments',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Departments) -- Department Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	  	 INSERT INTO @Lines(LineId)
 	  	 SELECT PL_Id
 	  	 FROM Prod_Lines_Base a
 	  	 JOIN @Departments b on b.DeptId = a.Dept_Id
 	  	 --SET @EquipmentList = ''
 	  	 --SELECT @EquipmentList =  @EquipmentList + CONVERT(nvarchar(10),LineId) + ',' 
 	  	 -- 	  	 FROM @Lines
 	  	 --DELETE FROM @Lines  
 	  	 --SET @EquipmentType = 2
 	 END
 	 IF @EquipmentType = 1  -- Units
 	 BEGIN
 	  	 INSERT INTO @Units(PUId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Units) -- Unit Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	  	 INSERT INTO @Lines(LineId)
 	  	 SELECT  DISTINCT a.PL_Id
 	  	 FROM Prod_Units a
 	  	 JOIN @Units b on b.puid = a.pu_id
 	 END
 	 IF @EquipmentType = 2 -- Lines
 	 BEGIN
 	  	 INSERT into @Lines (LineId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Lines',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Lines) -- Line Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	 END
 	 SELECT @LineID  =  min (lineid) from @Lines
END
 	 IF @TimeSelection IN (1,2,3,4,5,6,7,8,9,10) 
 	  	 EXECUTE dbo.spBF_CalculateOEEReportTime @LineId,@TimeSelection ,@StartTime  Output, @EndTime Output , @CappCurrentTime
 	 
END
