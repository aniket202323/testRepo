CREATE PROCEDURE dbo.spRS_AddPrinter
@Printer_Name varchar(50) 
AS
Declare @Exists int
Select @Exists = Printer_Id
From Report_Printers
Where Printer_Name = @Printer_Name
If @Exists Is Null
  Begin
    Insert Into Report_Printers(Printer_Name)
    Values(@Printer_Name)
  End
Else
  Return (1)
If @@Error = 0
  Return (0) -- Error during Insert
Else
  Return (2) -- Insert Ok
