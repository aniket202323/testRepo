CREATE PROCEDURE dbo.spEM_XRefCreate
  @DS_Id       	  Int,
  @Table_Id      Int,
  @Actual_Id     Int,
  @FKDesc 	  	  	  	  nvarchar(255),
  @User_Id       Int,
  @XRefId      	  Int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_XRefCreate',
                 Isnull(Convert(nVarChar(10),@DS_Id),'Null')  + ',' +
                 Isnull(Convert(nVarChar(10),@Table_Id),'Null')  + ',' +
                 Isnull(Convert(nVarChar(10),@Actual_Id),'Null')  + ',' +
                 Isnull(@FKDesc,'Null')  + ',' +
 	      Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  Insert into Data_Source_XRef(DS_Id,Table_Id,Actual_Id,Foreign_Key) VALUES(@DS_Id,@Table_Id,@Actual_Id,@FKDesc)
  SELECT @XRefId = DS_XRef_Id FROM Data_Source_XRef WHERE DS_Id = @DS_Id and Table_Id = @Table_Id and Actual_Id = @Actual_Id
  IF @XRefId IS NULL
    BEGIN
     ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@XRefId) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
