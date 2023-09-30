CREATE TABLE [WorkOrder].[received_messages] (
    [consumer_id]   VARCHAR (450) NOT NULL,
    [message_id]    VARCHAR (450) NOT NULL,
    [creation_time] BIGINT        DEFAULT (datediff_big(millisecond,'1970-01-01 00:00:00',getutcdate())) NULL,
    CONSTRAINT [PK_received_messages] PRIMARY KEY CLUSTERED ([consumer_id] ASC, [message_id] ASC)
);

