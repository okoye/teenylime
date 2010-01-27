import java.io.IOException;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class TMoteTLReset {

	public static void main(String[] args) {

		System.out.println("Opening connection for system-wide reset...");
		PhoenixSource phoenix = BuildSource.makePhoenix(args[0],
				PrintStreamMessenger.err);
		MoteIF mote = new MoteIF(phoenix);
		// Only the header is needed to trigger the reset
		TupleMsgHeader reset = new TupleMsgHeader();
		reset.set_operation(HeaderConstants.CTRL_RESET);
		try {
			mote.send(MoteIF.TOS_BCAST_ADDR, reset);
		} catch (IOException e1) {
			e1.printStackTrace();
			return;
		}
		try {
			Thread.sleep(3000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		System.exit(0);
	}
}
