CREATE PROCEDURE dbo.spEM_ImportVariable
  @Var_Desc      nvarchar(255),
  @DS_Id         int,
  @Data_Type_Id  int,
  @Eng_Units     nvarchar(15),
  @PUG_Order     int,
  @Var_Precision Tinyint_Precision,
  @PUG_Id        int,
  @Input_Tag     nVarChar(100),
  @Output_Tag    nVarChar(100),
  @PU_Id         int,
  @User_Id      int,
  @Var_Id        int OUTPUT
  AS
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create variable.
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ImportVariable',
                 @Var_Desc + ',' +
 	  	  Convert(nVarChar(10), @DS_Id) + ','  + 
 	  	  Convert(nVarChar(10), @Data_Type_Id) + ','  + 
 	  	  @Eng_Units + ','  + 
 	  	  Convert(nVarChar(10), @PUG_Order) + ','  + 
 	  	  Convert(nVarChar(10), @Var_Precision) + ','  + 
 	  	  Convert(nVarChar(10), @PUG_Id) + ','  + 
 	  	  @Input_Tag + ','  + 
 	  	  @Output_Tag + ','  + 
 	  	  Convert(nVarChar(10), @PU_Id) + ','  + 
 	  	  Convert(nVarChar(10), @User_Id),
                 dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Create a new variable.
  --
  Select @Var_Desc = right(@Var_Desc,50)
  Execute spEM_CreateVariable  @Var_Desc,@PU_Id, @PUG_Id, @PUG_Order, @User_Id , @Var_Id OUTPUT
  IF @Var_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  	  WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
  Else
 	 UpDate  Variables_Base Set DS_Id = @DS_Id,
              Data_Type_Id = @Data_Type_Id,
              Eng_Units = @Eng_Units,
              Var_Precision = @Var_Precision,
              Input_Tag = @Input_Tag,
              Output_Tag = @Output_Tag,
              Sampling_Interval =  CASE WHEN (@DS_Id = 2) THEN 0 ELSE NULL END
 	 Where Var_Id = @Var_Id
  --
  -- Return the id of the newly created variable.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@Var_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
