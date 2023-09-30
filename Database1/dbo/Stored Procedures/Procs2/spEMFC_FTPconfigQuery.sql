Create Procedure dbo.spEMFC_FTPconfigQuery 
@mode int,
@ID int,
@User_Id int
AS
  DECLARE @Insert_Id int 
 INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id, 'spEM_FTPconfigQuery' ,
               convert(nVarChar(10), @mode) + ',' + convert(nVarChar(10), @ID) + ','  + Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
if @mode = 0
 	 begin
 	  	 select c.FTP_Engine, c.FC_Desc, a.FA_Desc, c.Mask, c.Local_Path, c.Remote_Path, c.FC_Id, c.is_active, c.FA_Id
 	  	 from FTP_Config c
 	  	 Left Join FTP_Actions a On c.FA_Id = a.FA_Id
 	  	 order by c.FTP_Engine
 	 end
if @mode = -1
 	 begin
 	  	 delete from FTP_Config
 	  	 where FC_Id = @ID
 	 end
UPDATE Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
