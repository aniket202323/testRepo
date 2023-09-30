CREATE view SDK_V_PADataSource
as
select
Data_Source.DS_Id as Id,
Data_Source.DS_Desc as DataSource,
Data_Source.Active as IsActive
FROM Data_Source
