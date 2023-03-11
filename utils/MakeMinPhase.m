function y=MakeMinPhase(x)
%macht aus einem Spektrum x (als Spaltenvektor(en) angegeben) ein
%minimalphasiges Spektrum y (ebenfalls Spaltenvektoren).
%makeMinPhase benutzt die MATLAB-Funktion "hilbert", die das vollst�ndige
%Spektrum erwartet. Deshalb MUSS makeMinPhase vor loeRe ausgef�hrt werden!!

x1=x(1,:); xe=x(end,:); x=x(2:end-1,:);
y=x.*exp(-1i.*imag(hilbert(log(abs(x))))); %log in MATLAB ist ln
y=[x1;y;xe];

y=abs(x).*exp(-1i.*imag(hilbert(log(abs(x))))); %log in MATLAB ist ln
