## Top-Level Design
- CPU
  - finite state machine controller
  - datapath
- RAM (using the embedded memory block on the DE1-SoC)
- memory-mapped I/O interface (using the LEDs and switches on the DE1-SoC)

## Instruction Set Architecture (ISA)
The ISA of this machine is designed to be **Turing complete**:
<dl>
  <dt>Terminology</dt>
  <dd>Rn, Rd, Rm are 3 bit register number specifiers</dd>
  <dd>im8 is an 8 bit immediate operand</dd>
  <dd>im5 is a 5 bit immediate operand</dd>
  <dd>&lt;sh_op&gt; are shift operations on Rm (LSL#1, LSR#1, ASR#1)</dd>
  <dd>sh(R[m]) is the value of Rm after passing through the shifter and going into the Bin input of the ALU</dd>
  <dd>sx(f) is a sign extension of the immediate value f to 16 bits</dd>
  <dd>N, V, Z are the negative, overflow, and zero flags of the 3 bit status register</dd>
  <dd>R[x] is the 16 bit value stored in register x</dd>
  <dd>M[x] is the 16 bit value stored in RAM at address x</dd>
  <dd>PC is the program counter</dd>
  <dd>&lt;label&gt; is a syntax in the assembly language that indicates an instruction address</dd>
</dl>
<table>
  <tr>
    <th rowspan="2">Syntax</th>
    <th colspan="16">Binary Encoding</th>
    <th rowspan="2">Operation</th>
  </tr>
  <tr>
    <td>15</td>
    <td>14</td>
    <td>13</td>
    <td>12</td>
    <td>11</td>
    <td>10</td>
    <td>9</td>
    <td>8</td>
    <td>7</td>
    <td>6</td>
    <td>5</td>
    <td>4</td>
    <td>3</td>
    <td>2</td>
    <td>1</td>
    <td>0</td>
  </tr>
  <tr>
    <td>Register Transfer Instructions</td>
    <td colspan="3"><i>opcode</i></td>
    <td colspan="2"><i>op</i></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="8"><i>8b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>MOV Rn, #&lt;im8&gt;</code></td>
    <td colspan="3">110</td>
    <td colspan="2">10</td>
    <td colspan="3">Rn</td>
    <td colspan="8">im8</td>
    <td>R[n] = sx(im8)</td>
  </tr>
  <tr>
    <td></td>
    <td colspan="3"></td>
    <td colspan="2"></td>
    <td colspan="3"></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="2"><i>2b</i></td>
    <td colspan="3"><i>3b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>MOV Rd, Rm, &lt;sh_op&gt;</code></td>
    <td colspan="3">110</td>
    <td colspan="2">00</td>
    <td colspan="3">000</td>
    <td colspan="3">Rd</td>
    <td colspan="2">sh</td>
    <td colspan="3">Rm</td>
    <td>R[d] = sh(R[m])</td>
  </tr>
  <tr>
    <td>Arithmetic/Logical Instructions</td>
    <td colspan="3"><i>opcode</i></td>
    <td colspan="2"><i>op</i></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="2"><i>2b</i></td>
    <td colspan="3"><i>3b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>ADD Rd, Rn, Rm, &lt;sh_op&gt;</code></td>
    <td colspan="3">101</td>
    <td colspan="2">00</td>
    <td colspan="3">Rn</td>
    <td colspan="3">Rd</td>
    <td colspan="2">sh</td>
    <td colspan="3">Rm</td>
    <td>R[d] = R[n] + sh(R[m])</td>
  </tr>
  <tr>
    <td><code>AND Rd, Rn, Rm, &lt;sh_op&gt;</code></td>
    <td colspan="3">101</td>
    <td colspan="2">10</td>
    <td colspan="3">Rn</td>
    <td colspan="3">Rd</td>
    <td colspan="2">sh</td>
    <td colspan="3">Rm</td>
    <td>R[d] = R[n] &amp; sh(R[m])</td>
  </tr>
  <tr>
    <td><code>CMP Rn, Rm, &lt;sh_op&gt;</code></td>
    <td colspan="3">101</td>
    <td colspan="2">01</td>
    <td colspan="3">Rn</td>
    <td colspan="3">000</td>
    <td colspan="2">sh</td>
    <td colspan="3">Rm</td>
    <td>status = f(R[n] - sh(R[m]))</td>
  </tr>
  <tr>
    <td><code>MVN Rd, Rm, &lt;sh_op&gt;</code></td>
    <td colspan="3">101</td>
    <td colspan="2">11</td>
    <td colspan="3">000</td>
    <td colspan="3">Rd</td>
    <td colspan="2">sh</td>
    <td colspan="3">Rm</td>
    <td>R[d] = ~sh(R[m])</td>
  </tr>
  <tr>
    <td>Memory Instructions</td>
    <td colspan="3"><i>opcode</i></td>
    <td colspan="2"><i>op</i></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="5"><i>5b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>LDR Rd, [Rn, #&lt;im5&gt;]</code></td>
    <td colspan="3">011</td>
    <td colspan="2">00</td>
    <td colspan="3">Rn</td>
    <td colspan="3">Rd</td>
    <td colspan="5">im5</td>
    <td>R[d] = M[R[n] + sx(im5)]</td>
  </tr>
  <tr>
    <td><code>STR Rd, [Rn, #&lt;im5&gt;]</code></td>
    <td colspan="3">100</td>
    <td colspan="2">00</td>
    <td colspan="3">Rn</td>
    <td colspan="3">Rd</td>
    <td colspan="5">im5</td>
    <td>M[R[n] + sx(im5)] = R[d]</td>
  </tr>
  <tr>
    <td>Branch Instructions</td>
    <td colspan="3"><i>opcode</i></td>
    <td colspan="2"><i>op</i></td>
    <td colspan="3"><i>cond</i></td>
    <td colspan="8"><i>8b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>B &lt;label&gt;</code></td>
    <td colspan="3">001</td>
    <td colspan="2">00</td>
    <td colspan="3">000</td>
    <td colspan="8">im8</td>
    <td>PC += sx(im8)</td>
  </tr>
  <tr>
    <td><code>BEQ  &lt;label&gt;</code></td>
    <td colspan="3">001</td>
    <td colspan="2">00</td>
    <td colspan="3">001</td>
    <td colspan="8">im8</td>
    <td>if Z = 1 then PC += sx(im8)</td>
  </tr>
  <tr>
    <td><code>BNE &lt;label&gt;</code></td>
    <td colspan="3">001</td>
    <td colspan="2">00</td>
    <td colspan="3">010</td>
    <td colspan="8">im8</td>
    <td>if Z = 0 then PC += sx(im8)</td>
  </tr>
  <tr>
    <td><code>BLT &lt;label&gt;</code></td>
    <td colspan="3">001</td>
    <td colspan="2">00</td>
    <td colspan="3">011</td>
    <td colspan="8">im8</td>
    <td>if N != V then PC += sx(im8)</td>
  </tr>
  <tr>
    <td><code>BLE &lt;label&gt;</code></td>
    <td colspan="3">001</td>
    <td colspan="2">00</td>
    <td colspan="3">100</td>
    <td colspan="8">im8</td>
    <td>if (N != V or Z = 1) then PC += sx(im8)</td>
  </tr>
  <tr>
    <td>Function Call/Return Instructions</td>
    <td colspan="3"><i>opcode</i></td>
    <td colspan="2"><i>op</i></td>
    <td colspan="3"><i>Rn</i></td>
    <td colspan="8"><i>8b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>BL &lt;label&gt;</code></td>
    <td colspan="3">010</td>
    <td colspan="2">11</td>
    <td colspan="3">111</td>
    <td colspan="8">im8</td>
    <td>R7 = PC, PC += sx(im8)</td>
  </tr>
  <tr>
    <td></td>
    <td colspan="3"></td>
    <td colspan="2"></td>
    <td colspan="3"></td>
    <td colspan="3"><i>3b</i></td>
    <td colspan="5"><i>5b</i></td>
    <td></td>
  </tr>
  <tr>
    <td><code>BLX Rd</code></td>
    <td colspan="3">010</td>
    <td colspan="2">10</td>
    <td colspan="3">111</td>
    <td colspan="3">Rd</td>
    <td colspan="5">00000</td>
    <td>R7 = PC, PC = R[d]</td>
  </tr>
  <tr>
    <td><code>BX Rd</code></td>
    <td colspan="3">010</td>
    <td colspan="2">00</td>
    <td colspan="3">000</td>
    <td colspan="3">Rd</td>
    <td colspan="5">00000</td>
    <td>PC = R[d]</td>
  </tr>
  <tr>
    <td>Special Instructions</td>
    <td colspan="3"></td>
    <td colspan="2"></td>
    <td colspan="3"></td>
    <td colspan="3"></td>
    <td colspan="5"></td>
    <td></td>
  </tr>
  <tr>
    <td><code>HALT</code></td>
    <td colspan="3">111</td>
    <td colspan="2">00</td>
    <td colspan="3">000</td>
    <td colspan="3">000</td>
    <td colspan="5">00000</td>
    <td>wait</td>
  </tr>
</table>