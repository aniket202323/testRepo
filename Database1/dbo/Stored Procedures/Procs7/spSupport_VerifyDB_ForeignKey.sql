--Execute spSupport_VerifyDB_ForeignKey 'Sheet_Variables','Variables','SheetVars_FK_VarId','Var_Id','Var_Id','','','',''
create procedure dbo.spSupport_VerifyDB_ForeignKey
@RITableName varchar(100),
@RDTableName varchar(100),
@TrueKeyname varchar(100),
@RIFieldName1 varchar(100),
@RDFieldName1 varchar(100),
@RIFieldName2 varchar(100),
@RDFieldName2 varchar(100),
@RIFieldName3 varchar(100),
@RDFieldName3 varchar(100),
@CascadeDelete VarChar(1),
@CascadeUpdate VarChar(1)
AS
Declare
  @KeyId int,
  @RDTableId int,
  @Statement varchar(1000),
  @CUpdate   VarChar(1),
  @CDelete   VarChar(1)
Select @KeyId = NULL
Select @KeyId = Id,@CUpdate = Case When OBJECTPROPERTY(Id,'CnstIsUpdateCascade') = 1 Then '1' else '' End,@CDelete = Case When OBJECTPROPERTY(Id,'CnstIsDeleteCascade') = 1 Then '1' else '' End
 From sys.sysobjects Where (Name = @TrueKeyName) And (Type = 'F')
If (@KeyId Is Not NULL)
  Begin
 	 If @CUpdate = @CascadeUpdate and @CDelete = @CascadeDelete
 	   Begin
 	  	 Select @RDTableId = NULL
 	  	 Select @RDTableId = rkeyid from sys.sysforeignkeys Where (constid = @KeyId)
 	  	 Return
 	   End
 	 Select @Statement = 'ALTER TABLE dbo.' + @RITableName + ' DROP CONSTRAINT ' + @TrueKeyName 
 	 Execute (@Statement)
  End
Select @Statement = 'ALTER TABLE dbo.' + @RITableName + ' WITH NOCHECK ADD CONSTRAINT ' + @TrueKeyName + ' FOREIGN KEY (' + @RIFieldName1
If (@RIFieldName2 <> '') Select @Statement = @Statement + ',' + @RIFieldName2
If (@RIFieldName3 <> '') Select @Statement = @Statement + ',' + @RIFieldName3
Select @Statement = @Statement + ') REFERENCES dbo.' + @RDTableName + '(' + @RDFieldName1
If (@RDFieldName2 <> '') Select @Statement = @Statement + ',' + @RDFieldName2
If (@RDFieldName3 <> '') Select @Statement = @Statement + ',' + @RDFieldName3
Select @Statement = @Statement + ')'
If @CascadeDelete = '1' 
 	 Select @Statement = @Statement + ' ON DELETE CASCADE'
If @CascadeUpdate = '1'
 	 Select @Statement = @Statement + ' ON UPDATE CASCADE'
Execute (@Statement)
Select @Statement = 'Added Foreign Key [' + @TrueKeyName + '] [' + @RITableName + '] [' + @RDTableName + ']'
Print @Statement
