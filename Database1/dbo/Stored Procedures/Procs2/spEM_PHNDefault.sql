CREATE PROCEDURE dbo.spEM_PHNDefault
  @PHN_Id int,
  @User_Id int
  AS
  Declare @OldDefault Int,@Alias nvarchar(50),@OldType Int
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PHNDefault',
                Convert(nVarChar(10),@PHN_Id) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Select @OldDefault = Hist_Id,@Alias = Alias,@OldType = Hist_Type_Id From Historians Where Hist_Default = 1
/* Find old default and add \\servername\ to it*/
  BEGIN TRANSACTION
If @OldDefault <> @PHN_Id
BEGIN
 	 If @OldType = 7 -- local can only be numeric
 	 BEGIN
 	  	 Update Variables_Base Set Input_Tag = '\\'+ @Alias + '\' + Input_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Input_Tag) = 0 and isnumeric(Input_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set Output_Tag = '\\'+ @Alias + '\' + Output_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Output_Tag) = 0 and isnumeric(Output_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set DQ_Tag = '\\'+ @Alias + '\' + DQ_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',DQ_Tag) = 0 and isnumeric(DQ_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set LEL_Tag = '\\'+ @Alias + '\' + LEL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LEL_Tag) = 0 and isnumeric(LEL_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set LRL_Tag = '\\'+ @Alias + '\' + LRL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LRL_Tag) = 0 and isnumeric(LRL_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set LUL_Tag = '\\'+ @Alias + '\' + LUL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LUL_Tag) = 0 and isnumeric(LUL_Tag) = 1
 	  	 Update Variables_Base Set LWL_Tag = '\\'+ @Alias + '\' + LWL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LWL_Tag) = 0 and isnumeric(LWL_Tag) = 1
 	  	 Update Variables_Base Set Target_Tag = '\\'+ @Alias + '\' + Target_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Target_Tag) = 0 and isnumeric(Target_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set UWL_Tag = '\\'+ @Alias + '\' + UWL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UWL_Tag) = 0 and isnumeric(UWL_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set UUL_Tag = '\\'+ @Alias + '\' + UUL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UUL_Tag) = 0 and isnumeric(UUL_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set URL_Tag = '\\'+ @Alias + '\' + URL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',URL_Tag) = 0 and isnumeric(URL_Tag) = 1
 	  	 
 	  	 Update Variables_Base Set UEL_Tag = '\\'+ @Alias + '\' + UEL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UEL_Tag) = 0 and isnumeric(UEL_Tag) = 1
 	  	 
 	  	 Update e set Value =  replace(convert(Varchar(7000),Value),'PT:','PT:\\'+ @Alias + '\')
 	  	  	 From Event_Configuration_Values e 
 	  	  	 Join Event_Configuration_Data d on e.ECV_Id = d.ECV_Id 
 	  	  	 Join Ed_Fields ef on ef.ED_Field_Id = d.ED_Field_Id and ED_Field_Type_Id = 3
 	  	  	 Where e.Value like 'PT:%' and  Isnumeric(replace(convert(Varchar(7000),Value),'PT:','')) = 1 --   e.value not like 'PT:\\%'
 	 
 	 END
 	 ELSE
 	 BEGIN
 	  	 Update Variables_Base Set Input_Tag = '\\'+ @Alias + '\' + Input_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Input_Tag) = 0 and Input_Tag is Not Null 
 	  	 
 	  	 Update Variables_Base Set Output_Tag = '\\'+ @Alias + '\' + Output_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Output_Tag) = 0 and Output_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set DQ_Tag = '\\'+ @Alias + '\' + DQ_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',DQ_Tag) = 0 and DQ_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set LEL_Tag = '\\'+ @Alias + '\' + LEL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LEL_Tag) = 0 and LEL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set LRL_Tag = '\\'+ @Alias + '\' + LRL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LRL_Tag) = 0 and LRL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set LUL_Tag = '\\'+ @Alias + '\' + LUL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LUL_Tag) = 0 and LUL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set LWL_Tag = '\\'+ @Alias + '\' + LWL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',LWL_Tag) = 0 and LWL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set Target_Tag = '\\'+ @Alias + '\' + Target_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',Target_Tag) = 0 and Target_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set UWL_Tag = '\\'+ @Alias + '\' + UWL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UWL_Tag) = 0 and UWL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set UUL_Tag = '\\'+ @Alias + '\' + UUL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UUL_Tag) = 0 and UUL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set URL_Tag = '\\'+ @Alias + '\' + URL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',URL_Tag) = 0 and URL_Tag is Not Null
 	  	 
 	  	 Update Variables_Base Set UEL_Tag = '\\'+ @Alias + '\' + UEL_Tag
 	  	  	 Where DS_Id = 3 and CharIndex('\\',UEL_Tag) = 0 and UEL_Tag is Not Null
 	  	 
 	  	 Update e set Value =  replace(convert(Varchar(7000),Value),'PT:','PT:\\'+ @Alias + '\')
 	  	  	 From Event_Configuration_Values e 
 	  	  	 Join Event_Configuration_Data d on e.ECV_Id = d.ECV_Id 
 	  	  	 Join Ed_Fields ef on ef.ED_Field_Id = d.ED_Field_Id and ED_Field_Type_Id = 3
 	  	  	 Where e.Value like 'PT:%' and e.value not like 'PT:\\%'
 	 END
END
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Update the default flags.
  --
  UPDATE Historians SET Hist_Default = 0
  UPDATE Historians SET Hist_Default = 1 WHERE Hist_Id = @PHN_Id
  COMMIT TRANSACTION
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
