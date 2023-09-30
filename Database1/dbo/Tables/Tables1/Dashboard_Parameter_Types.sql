CREATE TABLE [dbo].[Dashboard_Parameter_Types] (
    [Dashboard_Parameter_Type_ID]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [dashboard_icon_id]                INT           NULL,
    [Dashboard_Parameter_Data_Type_ID] INT           NOT NULL,
    [dashboard_parameter_type_desc]    VARCHAR (100) CONSTRAINT [DF__dashboard__dashb__53C32D94] DEFAULT ('Parameter Type') NOT NULL,
    [Locked]                           BIT           NULL,
    [value_type]                       INT           CONSTRAINT [DF__dashboard__value__0A54486F] DEFAULT ((4)) NOT NULL,
    [version]                          INT           NULL,
    CONSTRAINT [PK_Dashboard_Parameters] PRIMARY KEY NONCLUSTERED ([Dashboard_Parameter_Type_ID] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_Dashboard_Parameters]
    ON [dbo].[Dashboard_Parameter_Types]([Dashboard_Parameter_Type_ID] ASC);

