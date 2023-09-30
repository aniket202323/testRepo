CREATE PROCEDURE dbo.spEM_PutPHNData
  @PHN_Id       int,
  @PHN_Username nvarchar(255),
  @PHN_Password nvarchar(255),
  @PHN_OS       int,
  @Hist_Type    int,
  @ServerName 	 nvarchar(255),
  @IsActive 	  	 TinyInt,
  @IsRemote 	  	 TinyInt,
  @User_Id int
  AS
  --
  Declare  @OldHistType 	 Int
  Select @OldHistType = Hist_Type_Id from Historians Where Hist_Id = @PHN_Id
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutPHNData',
        Substring(Convert(nVarChar(10),@PHN_Id) + ','  + 
 	  	 @PHN_Username + ','  + 
 	  	 @PHN_Password + ','  + 
 	  	 Convert(nVarChar(10),@PHN_OS) + ','  + 
 	  	 Convert(nVarChar(10),@Hist_Type) + ','  + 
 	  	 @ServerName + ','  + 
 	  	 Convert(nVarChar(10),@IsActive) + ','  + 
 	  	 Convert(nVarChar(10),@IsRemote) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),1,255),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Execute spCmn_Encryption2 @PHN_Password,'EncrYptoR',1,@PHN_Password Output
  UPDATE Historians
    SET Hist_Username = @PHN_Username,
        Hist_Password = @PHN_Password,
        Hist_OS_Id    = @PHN_OS,
 	  	 Hist_Type_Id  = @Hist_Type,
 	  	 Hist_ServerName  = @ServerName,
 	  	 Is_Active  	   = @IsActive,
 	  	 Is_Remote 	   = 	 @IsRemote
    WHERE Hist_Id  	   = @PHN_Id
  If @OldHistType <> @Hist_Type
 	 Begin
 	  	 Delete From Historian_Option_Data Where Hist_Id = @PHN_Id
 	  	 If @Hist_Type = 7 -- Proficy
 	  	  	 Insert into Historian_Option_Data(Hist_Id,Hist_Option_Id,Value)
 	  	  	  	 Select @PHN_Id,Hist_Option_Id,Value 
 	  	  	  	  	 From Historian_Option_Data
 	  	  	  	  	 Where Hist_Id = -1
 	  	 Else
 	  	  	 Insert into Historian_Option_Data(Hist_Id,Hist_Option_Id,Value)
 	  	  	  	 Select @PHN_Id,hto.Hist_Option_Id,hto.Hist_Option_Default_Value 
 	  	  	  	  	 From Historian_Type_Options hto 
 	  	  	  	  	 Where hto.Hist_Type_Id = @Hist_Type and Hist_Option_Default_Value is not null
 	 
 	 End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
