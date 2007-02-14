package org.pdtp;

import java.io.IOException;

public class EndpointException extends IOException {
    public EndpointException(Throwable cause) {
	super(cause.toString());
	setStackTrace(cause.getStackTrace());
    }
}
