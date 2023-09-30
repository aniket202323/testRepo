CREATE PROCEDURE dbo.spRS_GetASPPrintQue
AS
-------------------------------------
-- Local Variables
-------------------------------------
Declare @ReportServer  	 VarChar(255)
Declare @Printer  	  	 VarChar(255)
Declare @Printers  	  	 VarChar(7000)
Declare @PrintStyles  	 VarChar(7000)
Declare @ReportTypeId  	 Int
Declare @ReportId  	  	 Int
Declare @Template_Path 	 VarChar(255)
Declare @QId  	  	  	 Int
Declare @PrintOutCount  	 Int
Declare @URL  	  	  	 VarChar(255)
Declare @MaxPrintAttempts int
---------------------------------
-- Copy Of Current ASP Print Que
---------------------------------
CREATE TABLE #t(
 	 QId int, 
 	 ReportId int
)
---------------------------------------
-- Table To Build And Return To Caller
---------------------------------------
CREATE TABLE #Temp_PrintQue(
 	 QId int,
 	 ReportId int, 
 	 ReportTypeId int,
 	 Copies int, 
    URL varchar(255),
    PrinterName varchar(255))
-----------------------------------------------------------------------------
-- Table Containing Each Reports Individual Printer/PrintStyle Configuration
-----------------------------------------------------------------------------
Create Table #Printout(
 	 RowId int,
 	 PrinterId int,
 	 Copies int,
 	 PrinterName varchar(255)
)
---------------------------------------
-- Initialize Report Server Source URL
---------------------------------------
declare @USEHttps VARCHAR(255)
declare @protocol varchar(10)
set @protocol='http://'
SELECT @USEHttps = Value FROM Site_Parameters WHERE Parm_Id = 90
if (@USEHttps='1')
begin
 set @protocol='https://'
end
Select @ReportServer = @protocol + Value + '/' From Site_Parameters Where Parm_Id = 10 
---------------------------------------
-- Initialize Site Max Print Attempts
---------------------------------------
Select @MaxPrintAttempts = Convert(int, Value) From Site_Parameters Where Parm_Id = 309
----------------------------------
-- Initialize Temporary Print Que
----------------------------------
Insert Into #t(QId, ReportId) Select QId, ReportId from Report_ASPPrintQue where RunAttempts < @MaxPrintAttempts -- And reportid = 1053
----------------------------
-- Cursor Through Print Que
----------------------------
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select QId, ReportId  From #T
      )
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @QId, @ReportId 
  If (@@Fetch_Status = 0)
    Begin 
 	  	 delete from #Printout
 	  	 -- Get Report Type Id
 	  	 Select @ReportTypeId = Report_Type_Id From Report_Definitions Where Report_Id = @ReportId
 	  	 -- Get Template Path
 	  	 Select @Template_Path = Template_Path From Report_Types Where Report_Type_Id = @ReportTypeId
 	  	 -- Get Printers Parameter
 	  	 exec spRS_GetReportParamValue 'Printers', @ReportId, @Printers output
 	  	 If @Printers <> '1'
 	  	  	 Begin
 	  	  	  	 -- Get PrintStyles Parameter
 	  	  	  	 exec spRS_GetReportParamValue 'PrintStyles', @ReportId, @PrintStyles output
 	  	  	  	 -- What Are The Printers-Styles-Copies?
 	  	  	  	 Insert Into #Printout(RowId, PrinterId, Copies, PrinterName) Exec spRS_ReadPrintConfiguration @Printers, @PrintStyles
 	  	  	  	 select @PrintOutCount = Count(*) from #Printout
 	  	  	  	 --Decide whether or not to put report into result set
 	  	  	  	 If @PrintOutCount > 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @URL = @ReportServer + @Template_Path + '?PrintPage=1&ReportId=' + convert(varchar(5), @ReportId)
 	  	  	  	  	  	 Insert Into #Temp_PrintQue(QId, ReportId, ReportTypeId, URL, PrinterName, Copies) 
 	  	  	  	  	  	 Select @QId, @ReportId, @ReportTypeId, @URL, PrinterName, Copies From #Printout
 	  	  	  	  	 End -- @PrintOutCount > 0 
 	  	  	 End -- @Printers <> '1'
 	     Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
-- Cleanup The Result Set
Update #Temp_PrintQue Set URL = Replace(URL, '../', '')
--Update #Temp_PrintQue Set URL = 'http://usgb007/printing'
-- Return The Results
Select tp.ReportId, tp.Copies, tp.URL, tp.PrinterName, rd.Report_Name
from #Temp_PrintQue tp
Left Join Report_Definitions RD on tp.ReportId = rd.Report_Id
Drop Table #Temp_PrintQue
Drop Table #T
Drop Table #Printout
