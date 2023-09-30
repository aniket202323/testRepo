CREATE PROCEDURE dbo.spRS_AdminCopyReportTypeNegative
@OldId int,
@NewId int
AS
set nocount on
--Select @OldId = 192
--Select @NewId = -30
Print 'Deleting Old Report Type'
exec sprs_DeleteReportType @NewId
Print 'Creating New Report Type'
set identity_insert report_types on
Insert Into Report_types(Report_type_Id, version, description, template_path, class_name, native_ext, image_ext, send_parameters)
select @NewId, version, description + ' (Copy)', Template_Path, Class_Name, native_ext, image_ext, send_parameters from report_types where report_type_id = @OldId
set identity_insert report_types off
Print 'Adding Parameters'
insert into report_type_Parameters(Report_Type_Id, rp_Id, optional, default_value)
Select @NewId, rp_Id, optional, default_value from report_type_Parameters where report_type_id = @OldId
Print 'Adding Web Pages'
Insert Into Report_Type_Webpages(RWP_Id, Page_Order, Report_Type_Id)
Select RWP_Id, Page_Order, @NewId From Report_Type_Webpages where Report_Type_Id = @OldId
Print 'Adding Dependencies'
Insert Into Report_Type_Dependencies(Report_Type_Id, RDT_Id, Value)
Select @NewId, RDT_Id, Value From Report_Type_Dependencies Where Report_Type_Id = @OldId
Print 'Copy Complete'
Select * from Report_Types where REport_Type_Id = @NewId
