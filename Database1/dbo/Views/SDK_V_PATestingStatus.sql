CREATE view SDK_V_PATestingStatus
as
select
Test_Status.Testing_Status as Id,
Test_Status.Testing_Status_Desc as TestingStatus
from Test_Status
