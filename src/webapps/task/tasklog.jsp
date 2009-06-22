<%@ page
  contentType="text/html; charset=UTF-8"
  import="javax.servlet.*"
  import="javax.servlet.http.*"
  import="java.io.*"
%>
<%
  long logOffset = -1, logLength = -1;
  boolean tailLog = false;
  long tailSize = 1024;
  int tailWindow = 1;
  boolean entireLog = false;
  boolean plainText = false; 
  
  String taskId = request.getParameter("taskid");
  if (taskId == null) {
  	out.println("<h2>Missing 'taskid' for fetching logs!</h2>");
  	return;
  }
  
  String sLogOff = request.getParameter("off");
  if (sLogOff != null) {
  	logOffset = Long.valueOf(sLogOff).longValue();
  }
  
  String sLogLen = request.getParameter("len");
  if (sLogLen != null) {
  	logLength = Long.valueOf(sLogLen).longValue();
  }
  
  String sEntireLog = request.getParameter("all");
  if (sEntireLog != null) {
  	entireLog = Boolean.valueOf(sEntireLog);
  }
  
  String sTail = request.getParameter("tail");
  if (sTail != null) {
  	tailLog = Boolean.valueOf(sTail);
  }
  
  String sTailLen = request.getParameter("tailsize");
  if (sTailLen != null) {
  	tailSize = Long.valueOf(sTailLen).longValue();
  }
  
  String sTailWindow = request.getParameter("tailwindow");
  if (sTailWindow != null) {
  	tailWindow = Integer.valueOf(sTailWindow).intValue();
  }
  
  String sPlainText = request.getParameter("plaintext");
  if (sPlainText != null) {
    plainText = Boolean.valueOf(sPlainText);
  }

  if (logOffset == -1 || logLength == -1) {
  	tailLog = true;
  	tailWindow = 1;
  }

  if (entireLog) {
    tailLog = false;
  }
  
  if( !plainText ) {
    out.println("<html>");
    out.println("<title>" + taskId + "Task Logs </title>"); 
    out.println("<body>");
    out.println("<h1>" +  taskId + "Task Logs</h1><br>"); 
    out.println("<h2>Task Logs</h2>");
    out.println("<pre>");

  }
%>

<%
  boolean gotRequiredData = true;
  try {
  	TaskLog.Reader taskLogReader = new TaskLog.Reader(taskId);
    byte[] b = null;
  	int bytesRead = 0;
  	int targetLength = 0;

  	if (entireLog) {
  	  b = taskLogReader.fetchAll();
  	  targetLength = bytesRead = b.length;
  	} else {
  	  if (tailLog) {
  		b = new byte[(int)tailSize];
  		targetLength = (int)tailSize;
  		bytesRead = taskLogReader.tail(b, 0, b.length, tailSize, tailWindow);
  	  } else {
  		b = new byte[(int)logLength];
  		targetLength = (int)logLength;
  		bytesRead = taskLogReader.read(b, 0, b.length, logOffset, logLength);
   	  }
  	}
  	  
  	if (bytesRead != targetLength && 
  	  targetLength <= taskLogReader.getTotalLogSize()) {
  	  if( !plainText) {
	  	  out.println("<b>Warning: Could not fetch " + targetLength + 
	  		  " bytes from the task-logs; probably purged!</b><br/>");
  	  }else{
	  	  out.println("Warning: Could not fetch " + targetLength + 
  		  " bytes from the task-logs; probably purged!");
  	  }
  	  gotRequiredData = false;
  	}
  	if( plainText ) {
  	  response.setContentLength(bytesRead); 
  	}
	String logData = new String(b, 0, bytesRead);
	out.println(logData);
  } catch (IOException ioe) {
  	out.println("Failed to retrieve logs for task: " + taskId);
  }
  
  if( !plainText ) {
    out.println("</pre>");
  }
%>
<%
  if (!entireLog && !plainText) {
    if (tailLog) {
      if (gotRequiredData) {
  	  	out.println("<a href='/tasklog.jsp?taskid=" + taskId + 
  		    "&tail=true&tailsize=" + tailSize + "&tailwindow=" + (tailWindow+1) + 
  		    "'>Earlier</a>");
  	  }
  	  if (tailWindow > 1) {
        out.println("<a href='/tasklog.jsp?taskid=" + taskId + 
  	  	    "&tail=true&tailsize=" + tailSize + "&tailwindow=" + (tailWindow-1) 
  	  	    + "'>Later</a>");
  	  }
    } else {
      if (gotRequiredData) {
      	out.println("<a href='/tasklog.jsp?taskid=" + taskId + 
    		"&tail=false&off=" + Math.max(0, (logOffset-logLength)) +
  		  	"&len=" + logLength + "'>Earlier</a>");
  	  }
  	  out.println("<a href='/tasklog.jsp?taskid=" + taskId + 
  		  "&tail=false&off=" + (logOffset+logLength) +
  		  "&len=" + logLength + "'>Later</a>");
    }
  }
  if( !plainText ) {
    out.println("<hr>");
    out.println("<a href='http://lucene.apache.org/hadoop'>Hadoop</a>, 2006.<br>");
    out.println("</body>");
    out.println("</html>");
  }
%>