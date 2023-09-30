CREATE PROCEDURE dbo.spEM_RenamePHN
  @PHN_Id   int,
  @Alias nvarchar(255),
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenamePHN',
                Convert(nVarChar(10),@PHN_Id) + ','  + 
                @Alias + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  Declare @OldAlias nvarchar(255)
  Select @OldAlias = Alias from Historians Where Hist_Id = @PHN_Id
  Update Historians Set Alias = @Alias WHERE Hist_Id = @PHN_Id
  Update 
  Variables_Base Set Input_Tag = replace(Input_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  Output_Tag = replace(Output_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  DQ_Tag = replace(DQ_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  LEL_Tag = replace(LEL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  LRL_Tag = replace(LRL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  LUL_Tag = replace(LUL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  LWL_Tag = replace(LWL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  Target_Tag = replace(Target_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  UWL_Tag = replace(UWL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  UUL_Tag = replace(UUL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  URL_Tag = replace(URL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\'),
  UEL_Tag = replace(UEL_Tag,'\\'+ @OldAlias + '\','\\'+ @Alias + '\')
  Update Event_Configuration_Values set Value =  replace(convert(Varchar(7000),Value),'PT:\\'+ @OldAlias + '\','PT:\\'+ @Alias + '\')
 	 Where Value like 'pt:\\%'
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
