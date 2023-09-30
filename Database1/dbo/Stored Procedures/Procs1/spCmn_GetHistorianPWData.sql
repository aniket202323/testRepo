CREATE PROCEDURE dbo.spCmn_GetHistorianPWData 
  @Password varchar(255)
  AS
  Declare @HId Int,@HPW VarChar(255)
  Declare c insensitive Cursor  for select Hist_Id,Hist_Password From Historians
 	 Open c
cLoop:
    Fetch next From c Into @HId,@HPW
 	 If @@Fetch_Status = 0
 	   Begin
 	  	 If @HPW is not null and @HPW <> ''
 	  	  	 Execute spCmn_Encryption2 @HPW,@Password,0,@HPW Output
 	  	 Insert into  ##HistorianPW (Hist_Id,Hist_Password) Values (@HId,@HPW)
 	  	 goto cloop
 	   End
  Close c
  Deallocate c
