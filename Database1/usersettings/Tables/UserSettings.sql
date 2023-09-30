CREATE TABLE [usersettings].[UserSettings] (
    [id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [application_id]   INT            NOT NULL,
    [view_name]        VARCHAR (50)   NOT NULL,
    [data]             NVARCHAR (MAX) NULL,
    [user_name]        VARCHAR (255)  NOT NULL,
    [last_modified_on] DATETIME       NULL,
    [last_modified_by] VARCHAR (255)  NULL,
    CONSTRAINT [PK_UserSettings] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UK_UserSettings_App_Id_view_name_user_name] UNIQUE NONCLUSTERED ([application_id] ASC, [view_name] ASC, [user_name] ASC)
);

