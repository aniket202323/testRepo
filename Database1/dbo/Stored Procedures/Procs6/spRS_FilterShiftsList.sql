CREATE PROCEDURE [dbo].spRS_FilterShiftsList
@PuId 	  	  	  	 int ,
@StartTime 	  	  	 datetime,
@EndTime 	    	  	 datetime,
@Mask   	  	  	  	 VARCHAR (100),
@MaskFlag 	  	  	 tinyint,
@ExcludeStr varchar(8000),
@InTimeZone varchar(200)=NULL
AS 
 	 SET NOCOUNT ON
 	 Declare @INstr VarChar(7999)
 	 DECLARE @SQLStatement varchar(4000)
 	  
 	 Declare @Id varchar(10)
 	 Create Table #T (VarId Varchar(10))
 	 CREATE Table #temp(Id int Identity(1,1), Team_desc varchar(10))
 	  
 	  	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	  	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 	  
If @ExcludeStr Is Not Null
  Begin
 	 Select @INstr = @ExcludeStr + ','
  	 While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
 	   Begin
 	     Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	     insert into #T (VarId) Values (@Id)
 	     Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	     Select @INstr = Right(@INstr,Datalength(@INstr)-1)
 	   End
  End  
 	 
 	 DECLARE @FullMask 	  	 VARCHAR(50) 	 
 	 If @Mask Is Not Null
 	 Begin
 	  	 If @MaskFlag = 1 Select @FullMask = @Mask + '%'
 	  	 Else If @MaskFlag = 2 Select @FullMask = '%' + @Mask
 	  	 Else Select @FullMask = '%' + @Mask + '%'
 	 
 	 End
 	 If @Mask IS NULL
 	 BEGIN
 	  	 SELECT @FullMask='%'
 	 END 
 	 Print convert(varchar(5), @PUId)
 	 PRint @Mask 
 	 Print convert(varchar(20), @StartTime, 120) 
 	 /*SELECT @SQLStatement =  	 ' SELECT DISTINCT CREW_DESC AS TEAM_DESC ' +
 	  	  	  	  	  	  	  	  	  	 ' FROM   DBO.CREW_SCHEDULE C WHERE C.PU_ID= '+ convert(varchar(5), @PUId) + 
 	  	  	  	  	  	  	  	  	  	 ' AND C.CREW_DESC LIKE  ' + '''' + @Mask + ''''+
 	  	  	  	  	  	  	  	  	  	 ' AND C.Start_Time >=' + '''' + convert(varchar(20), @StartTime, 120) + '''' +
 	  	  	  	  	  	  	  	  	  	 ' AND C.End_Time <=' + '''' + convert(varchar(20), @EndTime, 120) + '''' +
 	  	  	  	  	  	  	  	  	  	 ' AND C.CREW_DESC NOT IN (SELECT VarID from #T)'+
 	  	  	  	  	  	  	  	  	  	 ' ORDER  BY CREW_DESC' 	  	 */
 	 INSERT INTO #temp (team_desc) SELECT DISTINCT Shift_DESC AS Shift_DESC 
 	 FROM DBO.CREW_SCHEDULE C
 	 WHERE C.PU_ID = @PuID AND C.Shift_DESC LIKE @FullMask
 	 AND C.Start_Time >=@StartTime AND C.End_Time <=@EndTime
 	 AND C.Shift_DESC NOT IN (select VarId from #T)
 	 ORDER BY Shift_DESC
SELECT * FROM #temp
DROP TABLE #temp 	 
