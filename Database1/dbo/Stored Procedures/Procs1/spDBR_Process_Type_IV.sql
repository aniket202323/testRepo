Create Procedure dbo.spDBR_Process_Type_IV
@xml ntext
AS
 	 create table ##ParamValue
 	 (
 	  	 Row int,
 	  	 Col int,
 	  	 Presentation bit,
 	  	 SPName varchar(50),
 	  	 Value varchar(7000),
 	  	 Header varchar(50)
 	 )
 	 declare @hDoc int
 	 Exec sp_xml_preparedocument @hDoc OUTPUT, @xml
 	 insert into ##ParamValue select * from OpenXML(@hDoc, N'/Root/_x0023_paramvalue')with ##ParamValue
 	 exec sp_xml_removedocument @hdoc
