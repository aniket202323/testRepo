-----------------------------------------------------------
-- Type: Stored Procedure
-- Name: spRS_ReportServerURLForSPCReport
-----------------------------------------------------------
CREATE PROCEDURE [dbo].[spRS_ReportServerURLForSPCReport]
@TimeStamp  	    	    	  datetime,
@VariableId  	    	    	  int,
@TestID  	    	    	    	  bigint,
@EventId  	    	    	  int,
@SheetId  	    	    	  int,
@UserId  	    	    	    	  int,
@Token  	    	    	    	  varchar(200)
--WITH ENCRYPTION
 AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/
DECLARE @ServerName as varchar(200)
DECLARE @TotalURL as varchar(1000)
DECLARE @ActualServer as Varchar(1000)
DECLARE @NDP as int
DECLARE @Seploc   	    	    	  INTEGER
DECLARE @Direction as int
DECLARE @StartTime as Datetime
DECLARE @DType_Id 	 as int
DECLARE @Prod_Id as int
DECLARE @CurStartId as Int
DECLARE @PUId as Int
DECLARE @sControlChart as varchar(1)
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
SELECT @TotalURL =@protocol
SELECT @NDP=25
SELECT @Direction= -1
SELECT @Servername= value from site_parameters where parm_id = 10
SELECT @StartTime=DateAdd(hh,-1,@TimeStamp)
-- Get unit and other attributes for the variable
SELECT       @DType_Id = Data_Type_Id,@PUId = PU_Id
FROM dbo.Variables v WITH (NOLOCK)
WHERE v.Var_Id = @VariableId
EXEC spServer_CmnGetRunningGrade @PUId, @StartTime, 1, @Prod_Id output, @CurStartId output
/** IF var is numeric the default chart will Xbar/MR, otherwise will be U chart 
                If Request.QueryString("ControlChart") = "0" 
                    ChartType.MR 
                ElseIf Request.QueryString("ControlChart") = "1" Then
                 	 ChartType.Range
                ElseIf Request.QueryString("ControlChart") = "2" Then
                    ChartType.Sigma
                ElseIf Request.QueryString("ControlChart") = "3" Then
                    ChartType.PChart
                ElseIf Request.QueryString("ControlChart") = "4" Then
                    ChartType.UChart
**/
IF @DType_Id IN (1,2 ) SET @sControlChart = '0' ELSE SET @sControlChart = '4'
IF (LEN(IsNull(@Servername,'')) > 0) AND UPPER(ISNULL(@Servername,'')) != '!NULL'   
  	  BEGIN
  	    	   IF CHARINDEX('/', @Servername) > 0
  	    	    	  BEGIN
  	    	    	    	  SELECT @Seploc = CHARINDEX('/', @Servername)
  	    	    	    	  BEGIN
  	    	    	    	    	  SELECT @ActualServer = Cast(left(@Servername, @Seploc-1) AS VarChar)
  	    	    	    	    	   
  	    	    	    	  END
  	    	    	  END
  	   END  	    	   
SELECT @ActualServer = @ActualServer + '/'+ 'Apps/APPLICATIONS/SPC CHARTS/SPCCHARTS.ASPX'
  	    	    	    	    	    	    	    	    	    	    + '?EndDate=' + Convert(varchar(25),@TimeStamp, 120) 
  	    	    	    	    	    	    	    	    	    	    + '&EndTime='+ Convert(varchar(25),@TimeStamp,120)  
  	    	    	    	    	    	    	    	    	    	    + '&EndTimeFormula='+ Convert(varchar(25),@TimeStamp, 120)
  	    	    	    	    	    	    	    	    	    	    + '&StartDate='+ Convert(varchar(25),@StartTime, 120) 
  	    	    	    	    	    	    	    	    	    	    + '&StartTime='+ Convert(varchar(25),@StartTime, 120) 
  	    	    	    	    	    	    	    	    	    	    + '&StartTimeFormula='+ Convert(varchar(25),@StartTime, 120)
  	    	    	    	    	    	    	    	    	    	    + '&Variable='+convert(varchar(10),@VariableID) 
  	    	    	    	    	    	    	    	    	    	    --+ '&TestID='+convert(varchar(10),@TestId)
  	    	    	    	    	    	    	    	    	    	    --+ '&UserId='+convert(varchar(4),@UserId)
  	    	    	    	    	    	    	    	    	    	    + '&No_Of_DataPoints='+convert(varchar(3),@NDP)
  	    	    	    	    	    	    	    	    	    	    + '&Direction='+convert(varchar(2),@Direction)
  	    	    	    	    	    	    	    	    	    	    + '&Token='+ @Token
 	  	  	  	  	  	  	  	  	  	    + '&ControlChart=' + @sControlChart 
 	  	  	  	  	  	  	  	  	  	    + '&Products=' + convert(varchar(10),@Prod_Id) 
SELECT @TotalURL = @TotalURl + @ActualServer 
--INSERT INTO @URL VALUES(@TotalURL)
SELECT @TotalURL   
SET ANSI_NULLS OFF
