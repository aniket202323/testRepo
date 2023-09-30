CREATE PROCEDURE [dbo].[spRS_ReadPrintConfiguration]
@Printers varchar(7000),
@PrintStyles varchar(7000)
AS
--------------------------------
-- Input String
--------------------------------
/*
Declare @Printers varchar(8000)
Declare @PrintStyles varchar(8000)
select @Printers = '2,3'
Select @PrintStyles = '1:6,1:4,2,5'
*/
----------------------------------
----------------------------------
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Declare @StyleStr varchar(10)
Declare @StyleId int
Declare @PrinterName varchar(255)
Declare @Colon int
Declare @Copies int
---------------------------------------
-- TABLE TO STORE THE DATA
---------------------------------------
Create Table #Printout(
 	 id int NOT NULL IDENTITY (1, 1),
 	 PrinterId int,
 	 Copies int,
 	 PrinterName varchar(255)
)
Create Table #PrintStyles(
 	 id int NOT NULL IDENTITY (1, 1),
 	 StyleId varchar(5),
 	 Copies int,
 	 StyleName varchar(255)
)
/*
select * from report_print_styles
Style_Id    Style_Name           
----------- -------------------- 
1           Paper
2           HTML
3           PDF
4           SNP
5           XLS
*/
------------------------------
-- Print Styles Table
------------------------------
Select @I = 1
Select @INstr = @PrintStyles + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @StyleStr = SubString(@INstr, 1, CharIndex(',',@INstr)-1)
 	 Select @Colon = CharIndex(':', @StyleStr)
 	 If (@Colon = 0)
 	   Begin
 	  	 Select @Copies = 1
 	  	 Select @StyleId = convert(int, @StyleStr)
 	   End
 	 Else
 	   Begin
 	  	 Select @Copies = SubString(@StyleStr, @Colon + 1, Len(@StyleStr) - @Colon)
 	  	 Select @StyleId = convert(int, SubString(@StyleStr, 1, @Colon - 1))
 	   End
 	 If @StyleId = 1
 	  	 Insert into #PrintStyles (StyleId, Copies) Values (@StyleId, @Copies)
 	 Select @I = @I + 1
 	 -----------------------
 	 -- SHORTEN THE STRING
 	 -----------------------
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
--select * from #PrintStyles
------------------------------
-- Printers Table
------------------------------
Select @I = 1
Select @INstr = @Printers + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr, 1, CharIndex(',',@INstr)-1)
 	 Select @PrinterName = Printer_Name From Report_Printers Where Printer_Id = @Id
 	 Insert into #Printout (PrinterId, PrinterName) Values (@Id, @PrinterName)
 	 Select @I = @I + 1
 	 -----------------------
 	 -- SHORTEN THE STRING
 	 -----------------------
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
--select *  from #Printout
select po.id, po.printerid, ps.copies, po.Printername
from #Printout po
Join #PrintStyles ps on ps.id = po.id
Drop Table #Printout
Drop table #PrintStyles
